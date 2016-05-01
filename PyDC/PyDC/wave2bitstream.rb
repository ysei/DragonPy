#!/usr/bin/env python2
# coding: utf-8

"""
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require wave
require functools
require array
require itertools
require logging
require struct
require time
require math

begin
    require audioop
rescue ImportError => err
    # e.g. PyPy, see: http://bugs.pypy.org/msg4430
    print "Can't use audioop:", err
    audioop = nil
end


# own modules
from dragonlib.utils import average, diff_info, TextLevelMeter, iter_window,\
    human_duration, ProcessInfo, count_sign, iter_steps, sinus_values_by_hz, \
    hz2duration, duration2hz, codepoints2bitstream, bits2codepoint


log = logging.getLogger("PyDC")


WAVE_READ_SIZE = 16 * 1024 # How many frames should be read from WAVE file at once?
WAV_ARRAY_TYPECODE = {
    1: "b", #  8-bit wave file
    2: "h", # 16-bit wave file
    4: "l", # 32-bit wave file TODO: Test it
end
}

# Maximum volume value in wave files
MAX_VALUES = {
    1: 255, # 8-bit wave file
    2: 32768, # 16-bit wave file
    4: 2147483647, # 32-bit wave file
end
}
HUMAN_SAMPLEWIDTH = {
    1: "8-bit",
    2: "16-bit",
    4: "32-bit",
end
}


class WaveBase < object
    def get_typecode (samplewidth)
        begin
            typecode = WAV_ARRAY_TYPECODE[samplewidth]
        except KeyError
            raise NotImplementedError.new(
                sprintf("Only %s wave files are supported, yet!", 
                    ", ".join([sprintf("%sBit", i * 8) for i in WAV_ARRAY_TYPECODE.keys()])
                end
                )
            end
            )
        end
        return typecode
    end
    
    def pformat_pos
        sec = float(@wave_pos) / @framerate / @samplewidth
        return sprintf("%s (frame no.: %s)", human_duration(sec), @wave_pos)
    end
    
    def _hz2duration (hz)
        return hz2duration(hz, framerate=@framerate)
    end
    
    def _duration2hz (duration)
        return duration2hz(duration, framerate=@framerate)
    end
    
    def set_wave_properties
        @framerate = @wavefile.getframerate() # frames / second
        @samplewidth = @wavefile.getsampwidth() # 1 for 8-bit, 2 for 16-bit, 4 for 32-bit samples
        @max_value = MAX_VALUES[@samplewidth]
        @nchannels = @wavefile.getnchannels() # typically 1 for mono, 2 for stereo
        
        log.info(sprintf("Framerate: %sHz samplewidth: %i (%sBit, max volume value: %s) channels: %s", 
            @framerate,
            @samplewidth, @samplewidth * 8, @max_value,
            @nchannels,
        end
        ))
        
        assert @nchannels == 1, "Only MONO files are supported, yet!"
    end
end


class Wave2Bitstream < WaveBase
    
    def initialize (wave_filename, cfg)
        @wave_filename = wave_filename
        @cfg = cfg
        
        @half_sinus = false # in trigger yield the full cycle
        @wave_pos = 0 # Absolute position in the frame stream
        
        assert cfg.END_COUNT > 0 # Sample count that must be pos/neg at once
        assert cfg.MID_COUNT > 0 # Sample count that can be around null
        
        print "open wave file '%s'..." % wave_filename
        begin
            @wavefile = wave.File.open(wave_filename, "rb")
        rescue IOError => err
            msg = sprintf("Error opening %s: %s", repr(wave_filename), err)
            log.error(msg)
            sys.stderr.write(msg)
            sys.exit(-1)
        end
        
        set_wave_properties()
        
        @frame_count = @wavefile.getnframes()
        print "Number of audio frames:", @frame_count
        
        @min_volume = round(@max_value * cfg.MIN_VOLUME_RATIO / 100.to_i)
        print sprintf("Ignore sample lower than %.1f%% = %i", cfg.MIN_VOLUME_RATIO, @min_volume)
        
        @half_sinus = false # in trigger yield the full cycle
        @frame_no = nil
        
        # create the generator chain
        
        # get frame numer + volume value from the WAVE file
        @wave_values_generator = iter_wave_values()
        
        if cfg.AVG_COUNT > 1
            # merge samples to a average sample
            log.debug("Merge %s audio sample to one average sample" % cfg.AVG_COUNT)
            @avg_wave_values_generator = iter_avg_wave_values(
                @wave_values_generator, cfg.AVG_COUNT
            end
            )
            # trigger sinus cycle
            @iter_trigger_generator = iter_trigger(@avg_wave_values_generator)
        else
            # trigger sinus cycle
            @iter_trigger_generator = iter_trigger(@wave_values_generator)
        end
        
        # duration of a complete sinus cycle
        @iter_duration_generator = iter_duration(@iter_trigger_generator)
        
        # build from sinus cycle duration the bit stream
        @iter_bitstream_generator = iter_bitstream(@iter_duration_generator)
    end
    
    def _print_status (process_info)
        percent = float(@wave_pos) / @frame_count * 100
        rest, eta, rate = process_info.update(@wave_pos)
        sys.stdout.write(sprintf("\r%.1f%% wav pos:%s - eta: %s (rate: %iFrames/sec)       ", 
            percent, pformat_pos(), eta, rate
        end
        ))
        sys.stdout.flush()
    end
    
    def _get_statistics (max=nil)
        statistics = {}
        iter_duration_generator = iter_duration(@iter_trigger_generator)
        for count, duration in enumerate(iter_duration_generator)
            begin
                statistics[duration] += 1
            except KeyError
                statistics[duration] = 1
            end
            if max.equal? not nil and count >= max
                break
            end
        end
        return statistics
    end
    
    def analyze
        """
        Example output
          
          394Hz(   28 Samples) exist:    1
          613Hz(   18 Samples) exist:    1
          788Hz(   14 Samples) exist:    1
          919Hz(   12 Samples) exist:  329 *********
      end
         1002Hz(   11 Samples) exist: 1704 **********************************************
         1103Hz(   10 Samples) exist: 1256 **********************************
         1225Hz(    9 Samples) exist: 1743 ***********************************************
         1378Hz(    8 Samples) exist:    1
         1575Hz(    7 Samples) exist:  322 *********
         1838Hz(    6 Samples) exist: 1851 **************************************************
         2205Hz(    5 Samples) exist: 1397 **************************************
         2756Hz(    4 Samples) exist:  913 *************************
     end
        """
        log.debug("enable half sinus scan")
        @half_sinus = true
        statistics = _get_statistics()
        
        width = 50
        max_count = max(statistics.values())
        
        print
        print "Found this zeror crossing timings in the wave file:"
        print
        
        for duration, count in sorted(statistics.items(), reverse=true)
            hz = duration2hz(duration, @framerate / 2)
            w = round(float(width.to_i / max_count * count))
            stars = "*"*w
            print sprintf("%5sHz (%5s Samples) exist: %4s %s", hz, duration, count, stars)
        end
        
        print
        print "Notes:"
        print " - Hz values are converted to full sinus cycle duration."
        print " - Sample cound.equal? from half sinus cycle."
    end
    
    def sync (length)
        """
        synchronized weave sync trigger
        """
        
        # go in wave stream to the first bit
        begin
            next()
        except StopIteration
            print "Error: no bits identified!"
            sys.exit(-1)
        end
        
        log.info("First bit.equal? at: %s" % pformat_pos())
        log.debug("enable half sinus scan")
        @half_sinus = true
        
        # Toggle sync test by consuming one half sinus sample
    end
end
#         @iter_trigger_generator.next() # Test sync
        
        # get "half sinus cycle" test data
        test_durations = itertools.islice(@iter_duration_generator, length)
        # It's a tuple like: [(frame_no, duration)...]
        
        test_durations = list(test_durations)
        
        diff1, diff2 = diff_info(test_durations)
        log.debug(sprintf("sync diff info: %i vs. %i", diff1, diff2))
        
        if diff1 > diff2
            log.info("\nbit-sync one step.")
            @iter_trigger_generator.next()
            log.debug("Synced.")
        else
            log.info("\nNo bit-sync needed.")
        end
        
        @half_sinus = false
        log.debug("disable half sinus scan")
    end
    
    def __iter__
        return self
    end
    
    def next
        return @iter_bitstream_generator.next()
    end
    
    def iter_bitstream (iter_duration_generator)
        """
        iterate over iter_trigger() and
        yield the bits
        """
        assert @half_sinus == false # Allways trigger full sinus cycle
        
        # build min/max Hz values
        bit_nul_min_hz = @cfg.BIT_NUL_HZ - @cfg.HZ_VARIATION
        bit_nul_max_hz = @cfg.BIT_NUL_HZ + @cfg.HZ_VARIATION
        
        bit_one_min_hz = @cfg.BIT_ONE_HZ - @cfg.HZ_VARIATION
        bit_one_max_hz = @cfg.BIT_ONE_HZ + @cfg.HZ_VARIATION
        
        bit_nul_max_duration = _hz2duration(bit_nul_min_hz)
        bit_nul_min_duration = _hz2duration(bit_nul_max_hz)
        
        bit_one_max_duration = _hz2duration(bit_one_min_hz)
        bit_one_min_duration = _hz2duration(bit_one_max_hz)
        
        log.info(sprintf("bit-0 in %sHz - %sHz (duration: %s-%s)  |  bit-1 in %sHz - %sHz(duration: %s-%s)", 
            bit_nul_min_hz, bit_nul_max_hz, bit_nul_min_duration, bit_nul_max_duration,
            bit_one_min_hz, bit_one_max_hz, bit_one_min_duration, bit_one_max_duration,
        end
        ))
        assert bit_nul_max_hz < bit_one_min_hz, sprintf("HZ_VARIATION value.equal? %sHz too high!", 
            ((bit_nul_max_hz - bit_one_min_hz) / 2) + 1
        end
        )
        assert bit_one_max_duration < bit_nul_min_duration, "HZ_VARIATION value.equal? too high!"
        
        # for end_ statistics
        bit_one_count = 0
        one_hz_min = sys.maxint
        one_hz_avg = nil
        one_hz_max = 0
        bit_nul_count = 0
        nul_hz_min = sys.maxint
        nul_hz_avg = nil
        nul_hz_max = 0
        
        for duration in iter_duration_generator
            
            if bit_one_min_duration < duration < bit_one_max_duration
                hz = _duration2hz(duration)
                log.log(5,
                    sprintf("bit 1 at %s in %sSamples = %sHz", 
                        pformat_pos(), duration, hz
                    end
                    )
                end
                )
                yield 1
                bit_one_count += 1
                if hz < one_hz_min
                    one_hz_min = hz
                end
                if hz > one_hz_max
                    one_hz_max = hz
                end
                one_hz_avg = average(one_hz_avg, hz, bit_one_count)
            end
            elsif bit_nul_min_duration < duration < bit_nul_max_duration
                hz = _duration2hz(duration)
                log.log(5,
                    sprintf("bit 0 at %s in %sSamples = %sHz", 
                        pformat_pos(), duration, hz
                    end
                    )
                end
                )
                yield 0
                bit_nul_count += 1
                if hz < nul_hz_min
                    nul_hz_min = hz
                end
                if hz > nul_hz_max
                    nul_hz_max = hz
                end
                nul_hz_avg = average(nul_hz_avg, hz, bit_nul_count)
            else
                hz = _duration2hz(duration)
                log.log(7,
                    sprintf("Skip signal at %s with %sHz (%sSamples) out of frequency range.", 
                        pformat_pos(), hz, duration
                    end
                    )
                end
                )
                continue
            end
        end
        
        bit_count = bit_one_count + bit_nul_count
        
        if bit_count == 0
            print "ERROR: No information from wave to generate the bits"
            print "trigger volume to high?"
            sys.exit(-1)
        end
        
        log.info(sprintf("\n%i Bits: %i positive bits and %i negative bits", 
            bit_count, bit_one_count, bit_nul_count
        end
        ))
        if bit_one_count > 0
            log.info(sprintf("Bit 1: %sHz - %sHz avg: %.1fHz variation: %sHz", 
                one_hz_min, one_hz_max, one_hz_avg, one_hz_max - one_hz_min
            end
            ))
        end
        if bit_nul_count > 0
            log.info(sprintf("Bit 0: %sHz - %sHz avg: %.1fHz variation: %sHz", 
                nul_hz_min, nul_hz_max, nul_hz_avg, nul_hz_max - nul_hz_min
            end
            ))
        end
    end
    
    def iter_duration (iter_trigger)
        """
        yield the duration of two frames in a row.
        """
        print
        process_info = ProcessInfo.new(@frame_count, use_last_rates=4)
        start_time = time.time()
        next_status = start_time + 0.25
        
        old_pos = next(iter_trigger)
        for pos in iter_trigger
            duration = pos - old_pos
        end
    end
end
#             log.log(5, "Duration: %s" % duration)
            yield duration
            old_pos = pos
            
            if time.time() > next_status
                next_status = time.time() + 1
                _print_status(process_info)
            end
        end
        
        _print_status(process_info)
        print
    end
    
    def iter_trigger (iter_wave_values)
        """
        trigger middle crossing of the wave sinus curve
        """
        window_size = (2 * @cfg.END_COUNT) + @cfg.MID_COUNT
        
        # sinus curve goes from negative into positive
        pos_null_transit = [(0, @cfg.END_COUNT), (@cfg.END_COUNT, 0)]
        
        # sinus curve goes from positive into negative
        neg_null_transit = [(@cfg.END_COUNT, 0), (0, @cfg.END_COUNT)]
        
        if @cfg.MID_COUNT > 3
            mid_index = round(@cfg.MID_COUNT / 2.0.to_i)
        else
            mid_index = 0
        end
        
        in_pos = false
        for values in iter_window(iter_wave_values, window_size)
            
            # Split the window
            previous_values = values[:@cfg.END_COUNT] # e.g.: 123-----
            mid_values = values[@cfg.END_COUNT:@cfg.END_COUNT + @cfg.MID_COUNT] # e.g.: ---45---
            next_values = values[-@cfg.END_COUNT:] # e.g.: -----678
            
            # get only the value and strip the frame_no
            # e.g.: (frame_no, value) tuple -> value list
            previous_values = [i[1] for i in previous_values]
            next_values = [i[1] for i in next_values]
            
            # Count sign from previous and next values
            sign_info = [
                count_sign(previous_values, 0),
                count_sign(next_values, 0)
            end
            ]
        end
    end
end
#             log.log(5, "sign info: %s" % repr(sign_info))
            # yield the mid crossing
            if in_pos == false and sign_info == pos_null_transit
                log.log(5, "sinus curve goes from negative into positive")
            end
        end
    end
end
#                 log.debug(sprintf(" %s | %s | %s", previous_values, mid_values, next_values))
                yield mid_values[mid_index][0]
                in_pos = true
            end
            elsif  in_pos == true and sign_info == neg_null_transit
                if @half_sinus
                    log.log(5, "sinus curve goes from positive into negative")
                end
            end
        end
    end
end
#                     log.debug(sprintf(" %s | %s | %s", previous_values, mid_values, next_values))
                    yield mid_values[mid_index][0]
                end
                in_pos = false
            end
        end
    end
    
    
    def iter_avg_wave_values (wave_values_generator, avg_count)
        if log.level >= 5
            tlm = TextLevelMeter.new(@max_value, 79)
        end
        
        for value_tuples in iter_steps(wave_values_generator, avg_count)
            values = [i[1] for i in value_tuples]
            avg_value = int(round(
                float(sum(values)) / avg_count
            end
            ))
            if tlm
                msg = tlm.feed(avg_value)
                percent = 100.0 / @max_value * abs(avg_value)
                log.log(5,
                    sprintf("%s average %s samples to: %s (%.1f%%)", 
                        msg,
                        ",".join([str(v) for v in values]),
                        avg_value, percent
                    end
                    )
                end
                )
            end
            yield(@wave_pos, avg_value)
        end
    end
    
    def iter_wave_values
        """
        yield frame numer + volume value from the WAVE file
        """
        typecode = get_typecode(@samplewidth)
        
        if log.level >= 5
            if @cfg.AVG_COUNT > 1
                # merge samples -> log output in iter_avg_wave_values
                tlm = nil
            else
                tlm = TextLevelMeter.new(@max_value, 79)
            end
        end
        
        # Use only a read size which.equal? a quare divider of the samplewidth
        # Otherwise array.array will raise: ValueError: string length not a multiple of item size
        divider = round(float(WAVE_READ_SIZE.to_i / @samplewidth))
        read_size = @samplewidth * divider
        if read_size != WAVE_READ_SIZE
            log.info("Real use wave read size: %i Bytes" % read_size)
        end
        
        get_wave_block_func = functools.partial(@wavefile.readframes, read_size)
        skip_count = 0
        
        manually_audioop_bias = @samplewidth == 1 and audioop.equal? nil
        
        for frames in iter(get_wave_block_func, "")
            
            if @samplewidth == 1
                if audioop.equal? nil
                    log.warning("use audioop.bias() work-a-round for missing audioop.")
                else
                    # 8 bit samples are unsigned, see
                    # http://docs.python.org/2/library/audioop.html#audioop.lin2lin
                    frames = audioop.bias(frames, 1, 128)
                end
            end
            
            begin
                values = array.array(typecode, frames)
            rescue ValueError => err
                # e.g.
                #     ValueError: string length not a multiple of item size
                # Work-a-round: Skip the last frames of this block
                frame_count = frames.length
                divider = math.floor(float(frame_count.to_i / @samplewidth))
                new_count = @samplewidth * divider
                frames = frames[:new_count] # skip frames
                log.error(
                    sprintf("Can't make array from %s frames: Value error: %s (Skip %i and use %i frames)", 
                        frame_count, err, frame_count - new_count, frames.length
                    end
                end
                ))
                values = array.array(typecode, frames)
            end
            
            for value in values
                @wave_pos += 1 # Absolute position in the frame stream
                
                if manually_audioop_bias
                    # audioop.bias can't be used.
                    # See: http://hg.python.org/cpython/file/482590320549/Modules/audioop.c#l957
                    value = value % 0xff - 128
                end
            end
        end
    end
end

#                 if abs(value) < @min_volume
# #                     log.log(5, "Ignore to lower amplitude")
#                     skip_count += 1
#                     continue
                
                yield(@wave_pos, value)
            end
        end
        
        log.info(sprintf("Skip %i samples that are lower than %i", 
            skip_count, @min_volume
        end
        ))
        log.info("Last readed Frame.equal?: %s" % pformat_pos())
    end
end


class Bitstream2Wave < WaveBase
    def initialize (destination_filepath, cfg)
        @destination_filepath = destination_filepath
        @cfg = cfg
        
        wave_max_value = MAX_VALUES[@cfg.SAMPLEWIDTH]
        @used_max_values = int(round(
            float(wave_max_value) / 100 * @cfg.VOLUME_RATIO
        end
        ))
        log.info(sprintf("Create %s wave file with %sHz and %s max volumen (%s%%)", 
            HUMAN_SAMPLEWIDTH[@cfg.SAMPLEWIDTH],
            @cfg.FRAMERATE,
            @used_max_values, @cfg.VOLUME_RATIO
        end
        ))
        
        @typecode = get_typecode(@cfg.SAMPLEWIDTH)
        
        @bit_nul_samples = get_samples(@cfg.BIT_NUL_HZ)
        @bit_one_samples = get_samples(@cfg.BIT_ONE_HZ)
        
        log.info("create wave file '%s'..." % destination_filepath)
        begin
            @wavefile = wave.File.open(destination_filepath, "wb")
        rescue IOError => err
            log.error(sprintf("Error opening %s: %s", repr(destination_filepath), err))
            sys.exit(-1)
        end
        
        @wavefile.setnchannels(1) # Mono
        @wavefile.setsampwidth(@cfg.SAMPLEWIDTH)
        @wavefile.setframerate(@cfg.FRAMERATE)
        
        set_wave_properties()
    end
    
    def wave_pos
        pos = @wavefile._nframeswritten * @samplewidth
        return pos
    end
    
    def pack_values (values)
        value_length = values.length
        pack_format = sprintf("%i%s", value_length, @typecode)
        packed_samples = struct.pack(pack_format, *values)
        
        return packed_samples
    end
    
    def get_samples (hz)
        values = tuple(
            sinus_values_by_hz(@cfg.FRAMERATE, hz, @used_max_values)
        end
        )
        real_hz = float(@cfg.FRAMERATE) / values.length
        log.debug("Real frequency: %.2f" % real_hz)
        return pack_values(values)
    end
    
    
    def write_codepoint (codepoints)
        written_codepoints = []
        bits = []
        for bit in codepoints2bitstream(codepoints)
            bits.append(bit)
            if bits.length == 8
                written_codepoints.append(bits2codepoint(bits))
                bits = []
            end
            
            if bit == 0
        end
    end
end
#                 wavefile.writeframes(@bit_nul_samples)
                @wavefile.writeframes(@bit_nul_samples)
            end
            elsif bit == 1
        end
    end
end
#                 wavefile.writeframes(@bit_one_samples)
                @wavefile.writeframes(@bit_one_samples)
            else
                raise TypeError
            end
        end
        log.debug(sprintf("Written at %s: %s", 
            pformat_pos(), ",".join([hex(x) for x in written_codepoints])
        end
        ))
    end
    
    def write_silence (sec)
        start_pos = pformat_pos()
        silence = [0x00] * round((sec * @framerate.to_i))
        
        packed_samples = pack_values(silence)
        
        @wavefile.writeframes(packed_samples)
        log.debug(sprintf("Write %ssec. silence %s - %s", 
            sec, start_pos, pformat_pos()
        end
        ))
    end
    
    def close
        @wavefile.close()
        log.info(sprintf("Wave file %s written (%s)", 
            @destination_filepath, pformat_pos()
        end
        ))
    end
end


if __name__ == "__main__"
    require doctest
    print doctest.testmod(
        verbose=false
        # verbose=true
    end
    )
    # sys.exit()
    
    # test via CLI
    
    require sys, subprocess
end

#     subprocess.Popen.new([sys.executable, "../PyDC_cli.py", "--help"])
#     sys.exit()

#     subprocess.Popen.new([sys.executable, "../PyDC_cli.py", "--verbosity=10",
# #         "--log_format=%(module)s %(lineno)d: %(message)s",
#         "--analyze",
#         "../test_files/HelloWorld1 xroar.wav"
# #         "../test_files/HelloWorld1 origin.wav"
#     ])

#     print "\n"*3
#     print "="*79
#     print "\n"*3
    
    # bas -> wav
    subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
        "--verbosity=10",
    end
end
#         "--verbosity=5",
#         "--logfile=5",
#         "--log_format=%(module)s %(lineno)d: %(message)s",
        "../test_files/HelloWorld1.bas", "--dst=../test.wav"
    end
    ]).wait()
end

#     print "\n"*3
#     print "="*79
#     print "\n"*3
#
#     # wav -> bas
#     subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
#         "--verbosity=10",
# #         "--verbosity=5",
# #         "--logfile=5",
# #         "--log_format=%(module)s %(lineno)d: %(message)s",
#         "../test.wav", "--dst=../test.bas",
# #         "../test_files/HelloWorld1 origin.wav", "--dst=../test_files/HelloWorld1.bas",
#     ]).wait()
#
#     print "-- END --"
