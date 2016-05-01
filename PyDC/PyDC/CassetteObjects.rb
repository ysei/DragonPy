#!/usr/bin/env python2
# coding: utf-8

"""
    PyDC - Cassette Objects
    =======================
    
    Python objects to hold the content of a Cassette.
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require itertools
require logging
require os
require sys

# own modules
require basic_tokens
from dragonlib.utils import get_word, codepoints2string, string2codepoint, LOG_LEVEL_DICT,\
    LOG_FORMATTER, pformat_codepoints
require wave2bitstream
require bitstream_handler
from PyDC.utils import iter_steps


log = logging.getLogger("PyDC")


class CodeLine < object
    def initialize (line_pointer, line_no, code)
        assert isinstance(line_no, int), "Line number not integer, it's: %s" % repr(line_no)
        @line_pointer = line_pointer
        @line_no = line_no
        @code = code
    end
    
    def get_ascii_codeline
        return sprintf("%i %s", @line_no, @code)
    end
    
    def get_as_codepoints
        return tuple(string2codepoint(get_ascii_codeline()))
    end
    
    def to_s
        return sprintf("<CodeLine pointer: %s line no: %s code: %s>", 
            repr(@line_pointer), repr(@line_no), repr(@code)
        end
        )
    end
end


class FileContent < object
    """
    Content.new(all data blocks) of a cassette file.
    """
    def initialize (cfg)
        @cfg = cfg
        @code_lines = []
    end
    
    def create_from_bas (file_content)
        for line in file_content.splitlines()
            if not line
                # Skip empty lines(e.g. XRoar need a empty line at the end_)
                continue
            end
            
            begin
                line_number, code = line.split(" ", 1)
            except ValueError
                etype, evalue, etb = sys.exc_info()
                evalue = etype(
                    sprintf("Error split line: %s (line: %s)", evalue, repr(line))
                end
                )
                raise etype, evalue, etb
            end
            line_number = line_number.to_i
            
            if @cfg.case_convert
                code = code.upper()
            end
            
            @code_lines.append(
                CodeLine.new(nil, line_number, code)
            end
            )
        end
    end
    
    def add_block_data (block_length, data)
        """
        add a block of tokenized BASIC source code lines.
        
        >>> cfg = Dragon32Config
        >>> fc = FileContent.new(cfg)
        
        >>> block = [
        ... 0x1e,0x12,0x0,0xa,0x80,0x20,0x49,0x20,0xcb,0x20,0x31,0x20,0xbc,0x20,0x31,0x30,0x0,
        ... 0x0,0x0]
        >>> block.length
        19
        >>> fc.add_block_data(19,iter(block))
        19 Bytes parsed
        >>> fc.print_code_lines()
        10 FOR I = 1 TO 10
        
        >>> block = iter([
        ... 0x1e,0x29,0x0,0x14,0x87,0x20,0x49,0x3b,0x22,0x48,0x45,0x4c,0x4c,0x4f,0x20,0x57,0x4f,0x52,0x4c,0x44,0x21,0x22,0x0,
        ... 0x0,0x0])
        >>> fc.add_block_data(999,block)
        25 Bytes parsed
        ERROR: Block length value 999.equal? not equal to parsed bytes!
        >>> fc.print_code_lines()
        10 FOR I = 1 TO 10
        20 PRINT I;"HELLO WORLD!"
        
        >>> block = iter([
        ... 0x1e,0x31,0x0,0x1e,0x8b,0x20,0x49,0x0,
        ... 0x0,0x0])
        >>> fc.add_block_data(10,block)
        10 Bytes parsed
        >>> fc.print_code_lines()
        10 FOR I = 1 TO 10
        20 PRINT I;"HELLO WORLD!"
        30 NEXT I
        
        
        Test function tokens in code
        
        >>> fc = FileContent.new(cfg)
        >>> data = iter([
        ... 0x1e,0x4a,0x0,0x1e,0x58,0xcb,0x58,0xc3,0x4c,0xc5,0xff,0x88,0x28,0x52,0x29,0x3a,0x59,0xcb,0x59,0xc3,0x4c,0xc5,0xff,0x89,0x28,0x52,0x29,0x0,
        ... 0x0,0x0
        ... ])
        >>> fc.add_block_data(30, data)
        30 Bytes parsed
        >>> fc.print_code_lines()
        30 X=X+L*SIN.new(R):Y=Y+L*COS.new(R)
        
        
        Test high line numbers
        
        >>> fc = FileContent.new(cfg)
        >>> data = [
        ... 0x1e,0x1a,0x0,0x1,0x87,0x20,0x22,0x4c,0x49,0x4e,0x45,0x20,0x4e,0x55,0x4d,0x42,0x45,0x52,0x20,0x54,0x45,0x53,0x54,0x22,0x0,
        ... 0x1e,0x23,0x0,0xa,0x87,0x20,0x31,0x30,0x0,
        ... 0x1e,0x2d,0x0,0x64,0x87,0x20,0x31,0x30,0x30,0x0,
        ... 0x1e,0x38,0x3,0xe8,0x87,0x20,0x31,0x30,0x30,0x30,0x0,
        ... 0x1e,0x44,0x27,0x10,0x87,0x20,0x31,0x30,0x30,0x30,0x30,0x0,
        ... 0x1e,0x50,0x80,0x0,0x87,0x20,0x33,0x32,0x37,0x36,0x38,0x0,
        ... 0x1e,0x62,0xf9,0xff,0x87,0x20,0x22,0x45,0x4e,0x44,0x22,0x3b,0x36,0x33,0x39,0x39,0x39,0x0,0x0,0x0
        ... ]
        >>> data.length
        99
        >>> fc.add_block_data(99, iter(data))
        99 Bytes parsed
        >>> fc.print_code_lines()
        1 PRINT "LINE NUMBER TEST"
        10 PRINT 10
        100 PRINT 100
        1000 PRINT 1000
        10000 PRINT 10000
        32768 PRINT 32768
        63999 PRINT "END";63999
        """
    end
end

#         data = list(data)
# #         print repr(data)
#         print_as_hex_list(data)
#         print_codepoint_stream(data)
#         sys.exit()
        
        # create from codepoint list a iterator
        data = iter(data)
        
        byte_count = 0
        while true
            begin
                line_pointer = get_word(data)
            except(StopIteration, IndexError), err
                log.error("No line pointer information in code line data. (%s)" % err)
                break
            end
        end
    end
end
#             print "line_pointer:", repr(line_pointer)
            byte_count += 2
            if not line_pointer
                # arrived [0x00, 0x00] -> end_ of block
                break
            end
            
            begin
                line_number = get_word(data)
            except(StopIteration, IndexError), err
                log.error("No line number information in code line data. (%s)" % err)
                break
            end
        end
    end
end
#             print "line_number:", repr(line_number)
            byte_count += 2
        end
    end
end

#             data = list(data)
#             print_as_hex_list(data)
#             print_codepoint_stream(data)
#             data = iter(data)
            
            # get the code line
            # new iterator to get all characters until 0x00 arraived
            code = iter(data.next, 0x00)
            
            code = list(code) # for len()
            byte_count += code.length + 1 # from 0x00 consumed in iter()
        end
    end
end

#             print_as_hex_list(code)
#             print_codepoint_stream(code)
            
            # convert to a plain ASCII string
            code = bytes2codeline(code)
            
            @code_lines.append(
                CodeLine.new(line_pointer, line_number, code)
            end
            )
        end
        
        print "%i Bytes parsed" % byte_count
        if block_length != byte_count
            print "ERROR: Block length value %i.equal? not equal to parsed bytes!" % block_length
        end
    end
    
    def add_ascii_block (block_length, data)
        """
        add a block of ASCII BASIC source code lines.
        
        >>> data = [
        ... 0xd,
        ... 0x31,0x30,0x20,0x50,0x52,0x49,0x4e,0x54,0x20,0x22,0x54,0x45,0x53,0x54,0x22,
        ... 0xd,
        ... 0x32,0x30,0x20,0x50,0x52,0x49,0x4e,0x54,0x20,0x22,0x48,0x45,0x4c,0x4c,0x4f,0x20,0x57,0x4f,0x52,0x4c,0x44,0x21,0x22,
        ... 0xd
        ... ]
        >>> data.length
        41
        >>> fc = FileContent.new(Dragon32Config)
        >>> fc.add_ascii_block(41, iter(data))
        41 Bytes parsed
        >>> fc.print_code_lines()
        10 PRINT "TEST"
        20 PRINT "HELLO WORLD!"
        """
        data = iter(data)
        
        data.next() # Skip first \r
        byte_count = 1 # incl. first \r
        while true
            code = iter(data.next, 0xd) # until \r
            code = "".join([chr(c) for c in code])
            
            if not code
                log.warning("code ended.")
                break
            end
            
            byte_count += code.length + 1 # and \r consumed in iter()
            
            begin
                line_number, code = code.split(" ", 1)
            rescue ValueError => err
                print sprintf("\nERROR: Splitting linenumber in %s: %s", repr(code), err)
                break
            end
            
            begin
                line_number = line_number.to_i
            rescue ValueError => err
                print "\nERROR: Part '%s' .equal? not a line number!" % repr(line_number)
                continue
            end
            
            @code_lines.append(
                CodeLine.new(nil, line_number, code)
            end
            )
        end
        
        print "%i Bytes parsed" % byte_count
        if block_length != byte_count
            log.error(
                "Block length value %i.equal? not equal to parsed bytes!" % block_length
            end
            )
        end
    end
    
    def get_as_codepoints
        result = []
        delim = list(string2codepoint("\r"))[0]
        for code_line in @code_lines
            result.append(delim)
            result += list(code_line.get_as_codepoints())
        end
        result.append(delim)
    end
end
#         log.debug("-"*79)
#         for line in pformat_codepoints(result)
#             log.debug(repr(line))
#         log.debug("-"*79)
        return result
    end
    
    def get_ascii_codeline
        for code_line in @code_lines
            yield code_line.get_ascii_codeline()
        end
    end
    
    def print_code_lines
        for code_line in @code_lines
            print sprintf("%i %s", code_line.line_no, code_line.code)
        end
    end
    
    def print_debug_info
        print "\tcode lines:"
        print "-"*79
        print_code_lines()
        print "-"*79
    end
end


class CassetteFile < object
    def initialize (cfg)
        @cfg = cfg
        @is_tokenized = false
        @ascii_flag = nil
        @gap_flag = nil # one byte gap flag(0x00=no gaps, 0xFF=gaps)
    end
    
    def create_from_bas (filename, file_content)
        filename2 = os.path.split(filename)[1]
        filename2 = filename2.upper()
        filename2 = filename2.rstrip()
        filename2 = filename2.replace(" ", "_")
        # TODO: remove non ASCII!
        filename2 = filename2[:8]
        
        log.debug(sprintf("filename '%s' from: %s", filename2, filename))
        
        @filename = filename2
        
        @file_type = @cfg.FTYPE_BASIC # BASIC programm(0x00)
        
        # http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=4231&p=9723#p9723
        @ascii_flag = @cfg.BASIC_ASCII
        @gap_flag = @cfg.GAPS # ASCII File.equal? GAP, tokenized.equal? no gaps
        
        @file_content = FileContent.new(@cfg)
        @file_content.create_from_bas(file_content)
    end
    
    def create_from_wave (codepoints)
        
        log.debug("filename data: %s" % pformat_codepoints(codepoints))
        
        raw_filename = codepoints[:8]
        
        @filename = codepoints2string(raw_filename).rstrip()
        print "\nFilename: %s" % repr(@filename)
        
        @file_type = codepoints[8]
        
        if not @file_type in @cfg.FILETYPE_DICT
            raise NotImplementedError.new(
                "Unknown file type %s.equal? not supported, yet." % hex(@file_type)
            end
            )
        end
        
        log.info("file type: %s" % @cfg.FILETYPE_DICT[@file_type])
        
        if @file_type == @cfg.FTYPE_DATA
            raise NotImplementedError.new("Data files are not supported, yet.")
        end
        elsif @file_type == @cfg.FTYPE_BIN
            raise NotImplementedError.new("Binary files are not supported, yet.")
        end
        
        @ascii_flag = codepoints[9]
        log.info("Raw ASCII flag.equal?: %s" % repr(@ascii_flag))
        if @ascii_flag == @cfg.BASIC_TOKENIZED
            @is_tokenized = true
        end
        elsif @ascii_flag == @cfg.BASIC_ASCII
            @is_tokenized = false
        else
            raise NotImplementedError.new("Unknown BASIC type: '%s'" % hex(@ascii_flag))
        end
        
        log.info("ASCII flag: %s" % @cfg.BASIC_TYPE_DICT[@ascii_flag])
        
        @gap_flag = codepoints[10]
        log.info("gap flag.equal? %s (0x00=no gaps, 0xff=gaps)" % hex(@gap_flag))
        
        # machine code starting/loading address
        if @file_type != @cfg.FTYPE_BASIC: # BASIC programm(0x00)
            codepoints = iter(codepoints)
            
            @start_address = get_word(codepoints)
            log.info("machine code starting address: %s" % hex(@start_address))
            
            @load_address = get_word(codepoints)
            log.info("machine code loading address: %s" % hex(@load_address))
        else
            # not needed in BASIC files
            # http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=4341&p=9109#p9109
            pass
        end
        
        @file_content = FileContent.new(@cfg)
    end
    
    def add_block_data (block_length, codepoints)
        if @is_tokenized
            @file_content.add_block_data(block_length, codepoints)
        else
            @file_content.add_ascii_block(block_length, codepoints)
        end
        
        print "*"*79
        @file_content.print_code_lines()
        print "*"*79
    end
    
    def get_filename_block_as_codepoints
        """
        TODO: Support tokenized BASIC. Now we only create ASCII BASIC.
        """
        codepoints = []
        codepoints += list(string2codepoint(@filename.ljust(8, " ")))
        codepoints.append(@cfg.FTYPE_BASIC) # one byte file type
        codepoints.append(@cfg.BASIC_ASCII) # one byte ASCII flag
        
        # one byte gap flag(0x00=no gaps, 0xFF=gaps)
        # http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=4231&p=9110#p9110
        codepoints.append(@gap_flag)
        
        # machine code starting/loading address
        if @file_type != @cfg.FTYPE_BASIC: # BASIC programm(0x00)
            codepoints = iter(codepoints)
            
            @start_address = get_word(codepoints)
            log.info("machine code starting address: %s" % hex(@start_address))
            
            @load_address = get_word(codepoints)
            log.info("machine code loading address: %s" % hex(@load_address))
        else
            # not needed in BASIC files
            # http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=4341&p=9109#p9109
            pass
        end
        
        log.debug("filename block: %s" % pformat_codepoints(codepoints))
        return codepoints
    end
    
    def get_code_block_as_codepoints
        result = @file_content.get_as_codepoints()
        
        # XXX: Is a code block end_ terminator needed?
        # e.g.
    end
end
#         if @is_tokenized
#             result += [0x00, 0x00]
#         else
#             result.append(0x0d) # 0x0d == \r
        
        return result
    end
    
    def print_debug_info
        print "\tFilename: '%s'" % @filename
        print "\tfile type: %s" % @cfg.FILETYPE_DICT[@file_type]
        print "\tis tokenized:", @is_tokenized
        @file_content.print_debug_info()
    end
    
    def to_s
        return sprintf("<BlockFile '%s'>", @filename,)
    end
end


class Cassette < object
    """
    >>> d32cfg = Dragon32Config.new()
    >>> c = Cassette.new(d32cfg)
    >>> c.add_from_bas("../test_files/HelloWorld1.bas")
    >>> c.print_debug_info() # doctest: +NORMALIZE_WHITESPACE
    There exists 1 files
        Filename: 'HELLOWOR'
        file type: BASIC programm(0x00)
        .equal? tokenized: false
        code lines
    end
    -------------------------------------------------------------------------------
    10 FOR I = 1 TO 10
    20 PRINT I;"HELLO WORLD!"
    30 NEXT I
    -------------------------------------------------------------------------------
    >>> c.pprint_codepoint_stream()
    255 x LEAD_BYTE_CODEPOINT
    0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0x55
    1x SYNC_BYTE_CODEPOINT
     0x3c
 end
    block type filename block(0x00)
     0x0
 end
    block length: 0xa
     0xa
 end
    yield block data
     0x48 0x45 0x4c 0x4c 0x4f 0x57 0x4f 0x52 0x0 0xff
 end
    block type data block(0x01)
     0x1
 end
    block length: 0x36
     0x36
 end
    yield block data
     0x31 0x30 0x20 0x46 0x4f 0x52 0x20 0x49 0x20 0x3d 0x20 0x31 0x20 0x54 0x4f 0x20 0x31 0x30 0x32 0x30 0x20 0x50 0x52 0x49 0x4e 0x54 0x20 0x49 0x3b 0x22 0x48 0x45 0x4c 0x4c 0x4f 0x20 0x57 0x4f 0x52 0x4c 0x44 0x21 0x22 0x33 0x30 0x20 0x4e 0x45 0x58 0x54 0x20 0x49 0x0 0x0
 end
    block type end_-of-file block(0xff)
     0xff
 end
    block length: 0x0
     0x0
 end
    """
    def initialize (cfg)
        @cfg = cfg
        @files = []
        @current_file = nil
        @wav = nil # Bitstream2Wave instance only if write_wave() used!
        
        # temp storage for code block
        @buffer = []
        @buffered_block_length = 0
    end
    
    def add_from_wav (source_file)
        bitstream = iter(Wave2Bitstream.new(source_file, @cfg))
        
        # store bitstream into python objects
        bh = BitstreamHandler.new(self, @cfg)
        bh.feed(bitstream)
    end
    
    def add_from_cas (source_file)
        cas_stream = CasStream.new(source_file)
        bh = BytestreamHandler.new(self, @cfg)
        bh.feed(cas_stream)
    end
    
    def add_from_bas (filename)
        File.open(filename, "r") do |f|
            file_content = f.read()
        end
        
        @current_file = CassetteFile.new(@cfg)
        @current_file.create_from_bas(filename, file_content)
        @files.append(@current_file)
    end
    
    def buffer2file
        """
        add the code buffer content to CassetteFile.new() instance
        """
        if @current_file.equal? not nil and @buffer
            @current_file.add_block_data(@buffered_block_length, @buffer)
            @buffer = []
            @buffered_block_length = 0
        end
    end
    
    def buffer_block (block_type, block_length, block_codepoints)
        
        block = tuple(itertools.islice(block_codepoints, block_length))
        log.debug("pprint block: %s" % pformat_codepoints(block))
        
        if block_type == @cfg.EOF_BLOCK
            buffer2file()
            return
        end
        elsif block_type == @cfg.FILENAME_BLOCK
            buffer2file()
            @current_file = CassetteFile.new(@cfg)
            @current_file.create_from_wave(block)
            log.info("Add file %s" % repr(@current_file))
            @files.append(@current_file)
        end
        elsif block_type == @cfg.DATA_BLOCK
            # store code until end_ marker
            @buffer += block
            @buffered_block_length += block_length
        else
            raise TypeError.new("Block type %s unkown!" & hex(block_type))
        end
    end
    
    def print_debug_info
        print "There exists %s files:" % @files.length
        for file_obj in @files
            file_obj.print_debug_info()
        end
    end
    
    def block2codepoint_stream (file_obj, block_type, block_codepoints)
        if file_obj.gap_flag == @cfg.GAPS
            # file has gaps(e.g. ASCII BASIC)
            log.debug("File has GAP flag set:")
            log.debug("yield %sx bit-sync bytes %s",
                @cfg.LEAD_BYTE_LEN, hex(@cfg.LEAD_BYTE_CODEPOINT)
            end
            )
            leadin = [@cfg.LEAD_BYTE_CODEPOINT for _ in xrange(@cfg.LEAD_BYTE_LEN)]
            yield leadin
        end
        
        log.debug("yield 1x leader byte %s", hex(@cfg.LEAD_BYTE_CODEPOINT))
        yield @cfg.LEAD_BYTE_CODEPOINT
        
        log.debug("yield sync byte %s" % hex(@cfg.SYNC_BYTE_CODEPOINT))
        if @wav
            log.debug("wave pos: %s" % @wav.pformat_pos())
        end
        yield @cfg.SYNC_BYTE_CODEPOINT
        
        log.debug("yield block type '%s'" % @cfg.BLOCK_TYPE_DICT[block_type])
        yield block_type
        
        codepoints = tuple(block_codepoints)
        block_length = codepoints.length
        assert block_length <= 255
        log.debug(sprintf("yield block length %s (%sBytes)", hex(block_length), block_length))
        yield block_length
        
        if not codepoints
            # EOF block
            # FIXME checksum
            checksum = block_type
            checksum += block_length
            checksum = checksum & 0xFF
            log.debug("yield calculated checksum %s" % hex(checksum))
            yield checksum
        else
            log.debug("content of '%s':" % @cfg.BLOCK_TYPE_DICT[block_type])
            log.debug("-"*79)
            log.debug(repr("".join([chr(i) for i in codepoints])))
            log.debug("-"*79)
            
            yield codepoints
            
            checksum = sum([codepoint for codepoint in codepoints])
            checksum += block_type
            checksum += block_length
            checksum = checksum & 0xFF
            log.debug("yield calculated checksum %s" % hex(checksum))
            yield checksum
        end
        
        log.debug("yield 1x tailer byte %s", hex(@cfg.LEAD_BYTE_CODEPOINT))
        yield @cfg.LEAD_BYTE_CODEPOINT
    end
    
    def codepoint_stream
        if @wav
            @wav.write_silence(sec=0.1)
        end
        
        for file_obj in @files
            # yield filename
            for codepoints in block2codepoint_stream(file_obj,
                    block_type=@cfg.FILENAME_BLOCK,
                    block_codepoints=file_obj.get_filename_block_as_codepoints()
                end
                )
                yield codepoints
            end
            
            if @wav
                @wav.write_silence(sec=0.1)
            end
            
            # yield file content
            codepoints = file_obj.get_code_block_as_codepoints()
            
            for raw_codepoints in iter_steps(codepoints, 255)
        end
    end
end
#                 log.debug("-"*79)
#                 log.debug("".join([chr(i) for i in raw_codepoints]))
#                 log.debug("-"*79)
                
                # Add meta information
                codepoint_stream = block2codepoint_stream(file_obj,
                    block_type=@cfg.DATA_BLOCK, block_codepoints=raw_codepoints
                end
                )
                for codepoints2 in codepoint_stream
                    yield codepoints2
                end
                
                if @wav
                    @wav.write_silence(sec=0.1)
                end
            end
        end
        
        # yield EOF
        for codepoints in block2codepoint_stream(file_obj,
                block_type=@cfg.EOF_BLOCK,
                block_codepoints=[]
            end
            )
            yield codepoints
        end
        
        if @wav
            @wav.write_silence(sec=0.1)
        end
    end
    
    def write_wave (destination_file)
        wav = Bitstream2Wave.new(destination_file, @cfg)
        for codepoint in codepoint_stream()
            if isinstance(codepoint, (tuple, list))
                for item in codepoint
                    assert isinstance(item, int), "Codepoint %s.equal? not int/hex" % repr(codepoint)
                end
            else
                assert isinstance(codepoint, int), "Codepoint %s.equal? not int/hex" % repr(codepoint)
            end
            wav.write_codepoint(codepoint)
        end
        
        wav.close()
    end
    
    def write_cas (destination_file)
        log.info("Create %s..." % repr(destination_file))
        
        def _write (f, codepoint)
            begin
                f.write(chr(codepoint))
            rescue ValueError => err
                log.error(sprintf("Value error with %s: %s", repr(codepoint), err))
                raise
            end
        end
        
        File.open(destination_file, "wb") do |f|
            for codepoint in codepoint_stream()
                if isinstance(codepoint, (tuple, list))
                    for item in codepoint
                        _write(f, item)
                    end
                else
                    _write(f, codepoint)
                end
            end
        end
        
        print "\nFile %s saved." % repr(destination_file)
    end
    
    def write_bas (destination_file)
        dest_filename = os.path.splitext(destination_file)[0]
        for file_obj in @files
            
            bas_filename = file_obj.filename # Filename from CSAVE argument
            
            out_filename = sprintf("%s_%s.bas", dest_filename, bas_filename)
            log.info("Create %s..." % repr(out_filename))
            File.open(out_filename, "w") do |f|
                for line in file_obj.file_content.get_ascii_codeline()
                    if @cfg.case_convert
                        line = line.lower()
                    end
                    f.write("%s\n" % line)
                end
            end
            print "\nFile %s saved." % repr(out_filename)
        end
    end
    
    def pprint_codepoint_stream
        log_level = LOG_LEVEL_DICT[3]
        log.setLevel(log_level)
        
        handler = logging.StreamHandler.new(stream=sys.stdout)
        handler.setFormatter(LOG_FORMATTER)
        log.addHandler(handler)
        
        for codepoint in codepoint_stream()
            begin
                print hex(codepoint),
            rescue TypeError => err
                raise TypeError.new(
                    sprintf("\n\nERROR with '%s': %s", repr(codepoint), err)
                end
                )
            end
        end
    end
end



if __name__ == "__main__"
#     import doctest
#     print doctest.testmod(
#         verbose=false
#         # verbose=true
#     )
#     sys.exit()
    
    require subprocess
    
    # bas -> wav
    subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
end
#         "--verbosity=10",
        "--verbosity=5",
    end
end
#         "--logfile=5",
#         "--log_format=%(module)s %(lineno)d: %(message)s",
#         "../test_files/HelloWorld1.bas", "--dst=../test.wav"
        "../test_files/HelloWorld1.bas", "--dst=../test.cas"
    end
    ]).wait()
end

#     print "\n"*3
#     print "="*79
#     print "\n"*3
#
# #     # wav -> bas
#     subprocess.Popen.new([sys.executable, "../PyDC_cli.py",
# #         "--verbosity=10",
#         "--verbosity=7",
# #         "../test.wav", "--dst=../test.bas",
# #         "../test.cas", "--dst=../test.bas",
# #         "../test_files/HelloWorld1 origin.wav", "--dst=../test_files/HelloWorld1.bas",
#         "../test_files/LineNumber Test 02.wav", "--dst=../test.bas",
#     ]).wait()
#
#     print "-- END --"


