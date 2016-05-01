#!/usr/bin/env python2
# coding: utf-8

"""
    Convert dragon 32 Cassetts WAV files
    ====================================
    
    TODO
        - write .BAS file
        - create GUI
    end
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""


require functools
require itertools
require logging
require os

log = logging.getLogger("PyDC")

# own modules
from dragonlib.utils import find_iter_window, iter_steps, MaxPosArraived,\
    print_bitlist, bits2codepoint, list2str, bitstream2codepoints, \
    PatternNotFound, count_the_same, codepoints2bitstream, pformat_codepoints


DISPLAY_BLOCK_COUNT = 8 # How many bit block should be printet in one line?

MIN_SAMPLE_VALUE = 5



class SyncByteNotFoundError < Exception
    pass
end


def pop_bytes_from_bit_list (bit_list, count)
    """
    >>> bit_str = (
    ... "00110011"
    ... "00001111"
    ... "01010101"
    ... "11001100")
    >>> bit_list = [i.to_i for i in bit_str]
    >>> bit_list, bytes = pop_bytes_from_bit_list(bit_list, 1)
    >>> bytes
    [[0, 0, 1, 1, 0, 0, 1, 1]]
    >>> bit_list, bytes = pop_bytes_from_bit_list(bit_list, 2)
    >>> bytes
    [[0, 0, 0, 0, 1, 1, 1, 1], [0, 1, 0, 1, 0, 1, 0, 1]]
    >>> bit_list, bytes = pop_bytes_from_bit_list(bit_list, 1)
    >>> bytes
    [[1, 1, 0, 0, 1, 1, 0, 0]]
    """
    data_bit_count = count * 8
    
    data_bit_list = bit_list[:data_bit_count]
    data = list(iter_steps(data_bit_list, steps=8))
    
    bit_list = bit_list[data_bit_count:]
    return bit_list, data
end




def print_block_table (block_codepoints)
    for block in block_codepoints
        byte_no = bits2codepoint(block)
        character = chr(byte_no)
        print sprintf("%s %4s %3s %s", 
            list2str(block), hex(byte_no), byte_no, repr(character)
        end
        )
    end
end


def print_as_hex (block_codepoints)
    line = ""
    for block in block_codepoints
        byte_no = bits2codepoint(block)
        character = chr(byte_no)
        line += hex(byte_no)
    end
    print line
end



class BitstreamHandlerBase < object
    def initialize (cassette, cfg)
        @cassette = cassette
        @cfg = cfg
    end
    
    def feed (bitstream)
        while true
            print "_"*79
        end
    end
    #         bitstream = list(bitstream)
    #         print " ***** Bitstream length:", bitstream.length
    #         bitstream = iter(bitstream)
            
            begin
                sync_bitstream(bitstream) # Sync bitstream with SYNC_BYTE
            rescue SyncByteNotFoundError => err
                log.error(err)
                log.info("Last wave pos: %s" % bitstream.pformat_pos())
                break
            end
            
            block_type, block_length, codepoints = get_block_info(bitstream)
            
            begin
                block_type_name = @cfg.BLOCK_TYPE_DICT[block_type]
            except KeyError
                print "ERROR: Block type %s unknown in BLOCK_TYPE_DICT!" % hex(block_type)
                print "-"*79
                print "Debug bitlist:"
                print_bitlist(bitstream)
                print "-"*79
                break
            end
            
            
            log.debug(
                sprintf("block type: 0x%x (%s)", block_type, block_type_name)
            end
            )
            
            @cassette.buffer_block(block_type, block_length, codepoints)
            
            if block_type == @cfg.EOF_BLOCK
                log.info("EOF-Block found")
                break
            end
            
            if block_length == 0
                print "ERROR: block length == 0 ???"
                print "-"*79
                print "Debug bitlist:"
                print_bitlist(bitstream)
                print "-"*79
                break
            end
            
            print "="*79
        end
        
        @cassette.buffer2file()
    end
    
    def get_block_info (codepoint_stream)
        block_type = next(codepoint_stream)
        log.info(sprintf("raw block type: %s (%s)", hex(block_type), repr(block_type)))
        
        block_length = next(codepoint_stream)
        
        # Get the complete block content
        codepoints = tuple(itertools.islice(codepoint_stream, block_length))
        
        begin
            verbose_block_type = @cfg.BLOCK_TYPE_DICT[block_type]
        except KeyError
            log.error("Blocktype unknown!")
            print pformat_codepoints(codepoints)
            sys.exit()
            verbose_block_type = hex(block_type)
        end
    end
end

#         log.debug("content of '%s':" % verbose_block_type)
#         log.debug("-"*79)
#         log.debug(pformat_codepoints(codepoints))
#         log.debug("-"*79)
        
        real_block_len = codepoints.length
        if real_block_len == block_length
            log.info("Block length: %sBytes, ok." % block_length)
        else
            log.error(sprintf("Block should be %sBytes but are: %sBytes!", block_length, real_block_len))
        end
        
        # Check block checksum
        
        origin_checksum = next(codepoint_stream)
        
        calc_checksum = sum([codepoint for codepoint in codepoints])
        calc_checksum += block_type
        calc_checksum += block_length
        calc_checksum = calc_checksum & 0xFF
        
        if calc_checksum == origin_checksum
            log.info("Block checksum %s.equal? ok." % hex(origin_checksum))
        else
            log.error(sprintf("Block checksum %s.equal? not equal with calculated checksum: %s", 
                hex(origin_checksum), hex(calc_checksum)
            end
            ))
        end
        
        # Check if the magic byte exists
    end
end

#         magic_byte = next(codepoint_stream)
#         if magic_byte != @cfg.MAGIC_BYTE
#             log.error(sprintf("Magic Byte %s.equal? not %s", hex(magic_byte), hex(@cfg.MAGIC_BYTE)))
#         else
#             log.info("Magic Byte %s, ok." % hex(magic_byte))
        
        return block_type, block_length, codepoints
    end
end



class BitstreamHandler < BitstreamHandlerBase
    """
    feed with wave bitstream
    """
    def get_block_info (bitstream)
        # convert the raw bitstream to codepoint stream
        codepoint_stream = bitstream2codepoints(bitstream)
        
        return super(BitstreamHandler, self).get_block_info(codepoint_stream)
    end
    
    def sync_bitstream (bitstream)
        log.debug("start sync bitstream at wave pos: %s" % bitstream.pformat_pos())
        bitstream.sync(32) # Sync bitstream to wave sinus cycle
    end
end

#         test_bitstream = list(itertools.islice(bitstream, 258 * 8))
#         print_bitlist(test_bitstream)
        
        log.debug("Searching for lead-in byte at wave pos: %s" % bitstream.pformat_pos())
        
        # Searching for lead-in byte
        lead_in_pattern = list(codepoints2bitstream(@cfg.LEAD_BYTE_CODEPOINT))
        max_pos = @cfg.LEAD_BYTE_LEN * 8
        begin
            leader_pos = find_iter_window(bitstream, lead_in_pattern, max_pos)
        rescue MaxPosArraived => err
            log.error(sprintf("Error: Leader-Byte '%s' (%s) not found in the first %i Bytes! (%s)", 
                list2str(lead_in_pattern), hex(@cfg.LEAD_BYTE_CODEPOINT),
                @cfg.LEAD_BYTE_LEN, err
            end
            ))
        rescue PatternNotFound => err
            log.error(sprintf("Error: Leader-Byte '%s' (%s) doesn't exist in bitstream! (%s)", 
                list2str(lead_in_pattern), hex(@cfg.LEAD_BYTE_CODEPOINT), err
            end
            ))
        else
            log.info(sprintf("Leader-Byte '%s' (%s) found at %i Bytes.new(wave pos: %s)", 
                list2str(lead_in_pattern), hex(@cfg.LEAD_BYTE_CODEPOINT),
                leader_pos, bitstream.pformat_pos()
            end
            ))
        end
        
        log.debug("Search for sync-byte at wave pos: %s" % bitstream.pformat_pos())
        
        # Search for sync-byte
        sync_pattern = list(codepoints2bitstream(@cfg.SYNC_BYTE_CODEPOINT))
        max_search_bits = @cfg.MAX_SYNC_BYTE_SEARCH * 8
        begin
            sync_pos = find_iter_window(bitstream, sync_pattern, max_search_bits)
        rescue MaxPosArraived => err
            raise SyncByteNotFoundError.new(
                sprintf("Error: Sync-Byte '%s' (%s) not found in the first %i Bytes! (%s)", 
                    list2str(sync_pattern), hex(@cfg.SYNC_BYTE_CODEPOINT),
                    @cfg.MAX_SYNC_BYTE_SEARCH, err
                end
                )
            end
            )
        rescue PatternNotFound => err
            raise SyncByteNotFoundError.new(
                sprintf("Error: Sync-Byte '%s' (%s) doesn't exist in bitstream! (%s)", 
                    list2str(sync_pattern), hex(@cfg.SYNC_BYTE_CODEPOINT),
                    err
                end
                )
            end
            )
        else
            log.info(sprintf("Sync-Byte '%s' (%s) found at %i Bytes.new(wave pos: %s)", 
                list2str(sync_pattern), hex(@cfg.SYNC_BYTE_CODEPOINT),
                sync_pos, bitstream.pformat_pos()
            end
            ))
        end
    end
end


class CasStream < object
    def initialize (source_filepath)
        @source_filepath = source_filepath
        @stat = os.stat(source_filepath)
        @file_size = @stat.st_size
        log.debug("file sizes: %s Bytes" % @file_size)
        @pos = 0
        @file_generator = __file_generator()
        
        @yield_ord = true
    end
    
    def __iter__
        return self
    end
    
    def next
        byte = @file_generator.next()
        if @yield_ord
            return ord(byte)
        else
            return byte
        end
    end
    
    def __file_generator
        max = @file_size + 1
        File.open(@source_filepath, "rb") do |f|
            for chunk in iter(functools.partial(f.read, 1024), "")
                for byte in chunk
                    @pos += 1
                    assert @pos < max
                    yield byte
                end
            end
        end
    end
    
    def get_ord
        byte = next()
        codepoint = ord(byte)
        return codepoint
    end
end


class BytestreamHandler < BitstreamHandlerBase
    """
    feed with byte stream e.g.: from cas file
    """
    def sync_bitstream (bitstream)
        leadin_bytes_count, sync_byte = count_the_same(bitstream, @cfg.LEAD_BYTE_CODEPOINT)
        if leadin_bytes_count == 0
            log.error("Leadin byte not found in file!")
        else
            log.info(sprintf("%s x leadin bytes (%s) found.", leadin_bytes_count, hex(@cfg.LEAD_BYTE_CODEPOINT)))
        end
        
        if sync_byte != @cfg.SYNC_BYTE_CODEPOINT
            log.error(sprintf("Sync byte wrong. Get %s but excepted %s", 
                hex(sync_byte), hex(@cfg.SYNC_BYTE_CODEPOINT)
            end
            ))
        else
            log.debug("Sync %s byte, ok." % hex(@cfg.SYNC_BYTE_CODEPOINT))
        end
    end
end



def print_bit_list_stats (bit_list)
    """
    >>> print_bit_list_stats([1,1,1,1,0,0,0,0])
    8 Bits: 4 positive bits and 4 negative bits
    """
    print "%i Bits:" % bit_list.length,
    positive_count = 0
    negative_count = 0
    for bit in bit_list
        if bit == 1
            positive_count += 1
        end
        elsif bit == 0
            negative_count += 1
        else
            raise TypeError.new("Not a bit: %s" % repr(bit))
        end
    end
    print sprintf("%i positive bits and %i negative bits", positive_count, negative_count)
end


if __name__ == "__main__"
    require doctest
    print doctest.testmod(
        verbose=false
        # verbose=true
    end
    )
end
#     sys.exit()
    
    # test via CLI
    
    require sys, subprocess
    
    # bas -> wav
    subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
        "--verbosity=10",
    end
end
#         "--verbosity=5",
#         "--logfile=5",
#         "--log_format=%(module)s %(lineno)d: %(message)s",
#         "../test_files/HelloWorld1.bas", "--dst=../test.wav"
        "../test_files/HelloWorld1.bas", "--dst=../test.cas"
    end
    ]).wait()
    
    print "\n"*3
    print "="*79
    print "\n"*3
end

#     # wav -> bas
    subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
end
#         "--verbosity=10",
        "--verbosity=7",
    end
end
#         "../test.wav", "--dst=../test.bas",
        "../test.cas", "--dst=../test.bas",
    end
end
#         "../test_files/HelloWorld1 origin.wav", "--dst=../test_files/HelloWorld1.bas",
    ]).wait()
    
    print "-- END --"
end
