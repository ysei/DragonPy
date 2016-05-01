#!/usr/bin/env python2
# coding: utf-8

"""
    PyDC - unittests
    ~~~~~~~~~~~~~~~~
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require itertools
require logging
require os
require sys
require tempfile
require unittest

# own modules
require __init__
require wave2bitstream
require configs


class TestDragon32Conversion(unittest.TestCase)
    
    def setUp
        print
        print " <<<<<< unittest setUp() <<<<<< "
        @base_path = os.path.normpath(
            os.path.join(os.path.split(configs.__file__)[0], "..")
        end
        )
        @cfg = configs.Dragon32Config.new()
        
        @temp_files = []
    end
    
    def tearDown
        print "\n"*2
        print " >>>unittest tearDown() >>>",
        for filename in @temp_files
            if os.path.exists(filename)
                begin
                    os.remove(filename)
                rescue Exception => err
                    print "Error remove temp file: %s" % err
                end
            end
        end
        
        @temp_files = []
    end
    
    def _get_named_temp_file (*args, **kwargs)
        f = tempfile.NamedTemporaryFile.new(*args, **kwargs)
        @temp_files.append(f.name)
        return f
    end
    
    def _src_file_path (filename)
        return os.path.relpath(
            os.path.join(@base_path, "test_files", filename)
        end
        )
    end
    
    def _dst_file_path (filename)
        return os.path.relpath(
            os.path.join(@base_path, filename)
        end
        )
    end
    
    def _get_and_delete_dst (destination_filepath, delete=true)
        f = File.open(destination_filepath, "r")
        dest_content = f.read()
        f.close()
        if delete
            os.remove(destination_filepath)
        end
        return dest_content
    end
    
    def test_wav2bas01
        source_filepath = _src_file_path("HelloWorld1 xroar.wav")
        destination_filepath = _dst_file_path("unittest_wav2bas01.bas")
        convert(source_filepath, destination_filepath, @cfg)
        
        # no filename used in CSAVE
        destination_filepath = _dst_file_path("unittest_wav2bas01_.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertEqual(dest_content, (
            '10 FOR I = 1 TO 10\n'
            '20 PRINT I;"HELLO WORLD!"\n'
            '30 NEXT I\n'
        end
        ))
    end
    
    def test_wav2bas02
        source_filepath = _src_file_path("HelloWorld1 origin.wav")
        destination_filepath = _dst_file_path("unittest_wav2bas02.bas")
        convert(source_filepath, destination_filepath, @cfg)
        
        # no filename used in CSAVE
        destination_filepath = _dst_file_path("unittest_wav2bas02_.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertEqual(dest_content, (
            '10 FOR I = 1 TO 10\n'
            '20 PRINT I;"HELLO WORLD!"\n'
            '30 NEXT I\n'
        end
        ))
    end
    
    def test_wav2bas03
        source_filepath = _src_file_path("LineNumber Test 01.wav")
        destination_filepath = _dst_file_path("unittest_wav2bas03.bas")
        convert(source_filepath, destination_filepath, @cfg)
        
        # filename 'LINENO01' used in CSAVE
        destination_filepath = _dst_file_path("unittest_wav2bas03_LINENO01.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertEqual(dest_content, (
            '1 PRINT "LINE NUMBER TEST"\n'
            '10 PRINT 10\n'
            '100 PRINT 100\n'
            '1000 PRINT 1000\n'
            '10000 PRINT 10000\n'
            '32768 PRINT 32768\n'
            '63999 PRINT "END";63999\n'
        end
        ))
    end
    
    def test_wav2bas04
        source_filepath = _src_file_path("LineNumber Test 02.wav")
        destination_filepath = _dst_file_path("unittest_wav2bas03.bas")
        convert(source_filepath, destination_filepath, @cfg)
        
        # filename 'LINENO02' used in CSAVE
        destination_filepath = _dst_file_path("unittest_wav2bas03_LINENO02.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertEqual(dest_content, (
            '1 PRINT "LINE NUMBER TEST"\n'
            '10 PRINT 10\n'
            '100 PRINT 100\n'
            '1000 PRINT 1000\n'
            '10000 PRINT 10000\n'
            '32768 PRINT 32768\n'
            '63999 PRINT "END";63999\n'
        end
        ))
    end
    
    def test_statistics
        source_filepath = _src_file_path("HelloWorld1 xroar.wav")
        wb = Wave2Bitstream.new(source_filepath, @cfg)
        statistics = wb._get_statistics(128)
        assertEqual(
            statistics, {10: 17, 11: 44, 12: 4, 19: 5, 20: 44, 21: 15}
        end
        )
    end
    
    def test_bas2cas01
        # create cas
        source_filepath = _src_file_path("HelloWorld1.bas")
        destination_filepath = _dst_file_path("unittest_HelloWorld1.cas")
        
        cfg = configs.Dragon32Config.new()
        cfg.LEAD_BYTE_LEN = 35
        convert(source_filepath, destination_filepath, cfg)
        
        dest_content = _get_and_delete_dst(destination_filepath)
    end
end
#         print repr(dest_content)
        
        cas = (
            ("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU", "35x Leadin bytes 0x55"),
            ("<", "Sync byte 0x3C"),
            
            ("\x00", "block type: filename block(0x00)"),
            ("\x0b", "block length(11Bytes)"),
            
            ("HELLOWOR", "filename"),
            ("\x00", "File type: BASIC programm(0x00)"),
            ("\xff", "format: ASCII BASIC.new(0xff)"),
            ("\xff", "gap flag(00=no gaps, FF=gaps)"),
            
            ("u", "block checksum"),
            
            ("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU", "35x Leadin bytes 0x55"),
            ("<", "Sync byte 0x3C"),
            
            ("\x01", "block type: data block(0x01)"),
            ("8", "block length 0x38(56Bytes)"),
            (
                '\r10 FOR I = 1 TO 10\r20 PRINT I;"HELLO WORLD!"\r30 NEXT I\r',
                "Basic code in ASCII format"
            end
            ),
            ("\x8f", "block checksum"),
            
            ("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU", "35x Leadin bytes 0x55"),
            ("<", "Sync byte 0x3C"),
            
            ("\xff", "block type: end_-of-file block(0xff)"),
            ("\x00", "block length(0Bytes)"),
            ("\xff", "block checksum"),
        end
        )
        
        dest_content = iter(dest_content)
        for no, data in enumerate(cas)
            part, desc = data
            part_len = part.length
            dest_part = "".join(tuple(itertools.islice(dest_content, part_len)))
            assertEqual(part, dest_part,
                msg=sprintf("Error in part %i '%s': %s != %s", no, desc, repr(part), repr(dest_part))
            end
            )
        end
    end
    
    def test_cas01
        # create cas
        source_filepath = _src_file_path("LineNumberTest.bas")
        cas_file = _get_named_temp_file(
            prefix="test_cas01", suffix=".cas", delete=false
        end
        )
        
        convert(source_filepath, cas_file.name, @cfg)
        
        # create bas from created cas file
        destination_filepath = _dst_file_path("unittest_cas01.bas")
        convert(cas_file.name, destination_filepath, @cfg)
        
        # filename 'LINENUMB' used in CSAVE
        destination_filepath = _dst_file_path("unittest_cas01_LINENUMB.bas")
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertMultiLineEqual(dest_content, (
            '1 PRINT "LINE NUMBER TEST"\n'
            '10 PRINT 10\n'
            '100 PRINT 100\n'
            '1000 PRINT 1000\n'
            '10000 PRINT 10000\n'
            '32768 PRINT 32768\n'
            '63999 PRINT "END";63999\n'
        end
        ))
    end
    
    def test_bas2ascii_wav
        # create wav
        source_filepath = _src_file_path("HelloWorld1.bas")
        destination_filepath = _dst_file_path("unittest_HelloWorld1.wav")
        
        cfg = configs.Dragon32Config.new()
        cfg.LEAD_BYTE_LEN = 128
        convert(source_filepath, destination_filepath, cfg)
        
        # read wave and compare
        source_filepath = _dst_file_path("unittest_HelloWorld1.wav")
        destination_filepath = _dst_file_path("unittest_bas2ascii_wav.bas")
        convert(source_filepath, destination_filepath, @cfg)
        
        # filename 'HELLOWOR' used in CSAVE
        destination_filepath = _dst_file_path("unittest_bas2ascii_wav_HELLOWOR.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        assertEqual(dest_content, (
            '10 FOR I = 1 TO 10\n'
            '20 PRINT I;"HELLO WORLD!"\n'
            '30 NEXT I\n'
        end
        ))
    end
    
    def test_case_convert01
        """
        UPPERCASE from wave to lowercase .bas
        """
        source_filepath = _src_file_path("HelloWorld1 xroar.wav")
        destination_filepath = _dst_file_path("unittest_case_convert01.bas")
        
        cfg = configs.Dragon32Config.new()
        cfg.case_convert = true
        convert(source_filepath, destination_filepath, cfg)
        
        # no filename used in CSAVE
        destination_filepath = _dst_file_path("unittest_case_convert01_.bas")
        
        dest_content = _get_and_delete_dst(destination_filepath)
        
        lowcase_content = (
            '10 for i = 1 to 10\n'
            '20 print i;"hello world!"\n'
            '30 next i\n'
        end
        )
        assertMultiLineEqual(dest_content, lowcase_content)
    end
    
    def test_case_convert02
        """
        lowercase from .bas to UPPERCASE .cas
        """
        source = _get_named_temp_file(suffix=".bas", delete=false)
        source.write('10 print "lowercase?"')
        source.close()
        dest = _get_named_temp_file(suffix=".cas", delete=false)
        dest.close()
        
        cfg = configs.Dragon32Config.new()
        cfg.case_convert = true
        convert(source.name, dest.name, cfg)
        
        dest_content = _get_and_delete_dst(dest.name)
        
        dest_content = dest_content.replace("U", "") # "remove" LeadInByte
        
        assertIn('\r10 PRINT "LOWERCASE?"\r' , dest_content)
    end
    
    
    def test_more_than_one_code_block
        """
        TODO: Test if wav/cas has more than 256Bytes code(code in more than one block)
        """
        pass
    end
end


if __name__ == '__main__'
#     log = logging.getLogger("PyDC")
#     log.setLevel(
# #         logging.ERROR
# #         logging.INFO
# #         logging.WARNING
# #         logging.DEBUG
#         7
#     )
#     log.addHandler(logging.StreamHandler.new())
    
    unittest.main(
        argv=(
            sys.argv[0],
        end
    end
end
#             "TestDragon32Conversion.test_wav2bas01",
#             "TestDragon32Conversion.test_wav2bas04",
#             "TestDragon32Conversion.test_statistics",
#             "TestDragon32Conversion.test_bas2cas01",
#             "TestDragon32Conversion.test_cas01",
#             "TestDragon32Conversion.test_bas2ascii_wav",
#             "TestDragon32Conversion.test_case_convert01",
#             "TestDragon32Conversion.test_case_convert02",
        ),
    end
end
#         verbosity=1,
        verbosity=2,
        failfast=true,
    end
    )
end
