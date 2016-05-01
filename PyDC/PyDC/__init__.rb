#!/usr/bin/env python2
# coding: utf-8

"""
    Python dragon 32 converter
    ==========================
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require os
require sys

require CassetteObjects


__version__ = (0, 1, 0, 'dev')
VERSION_STRING = '.'.join(str(part) for part in __version__)

TITLE_LINE = "PyDC v%s copyleft 2013 by htfx.de - Jens Diemer, GNU GPL v3 or above" % VERSION_STRING


def analyze (wave_file, cfg)
    wb = Wave2Bitstream.new(wave_file, cfg)
    wb.analyze()
end


def convert (source_file, destination_file, cfg)
    """
    convert in every way.
    """
    source_ext = os.path.splitext(source_file)[1]
    source_ext = source_ext.lower()
    
    dest_ext = os.path.splitext(destination_file)[1]
    dest_ext = dest_ext.lower()
    
    if source_ext not in(".wav", ".cas", ".bas")
        raise AssertionError.new(
            "Source file type %r not supported." % repr(source_ext)
        end
        )
    end
    if dest_ext not in(".wav", ".cas", ".bas")
        raise AssertionError.new(
            "Destination file type %r not supported." % repr(dest_ext)
        end
        )
    end
    
    print sprintf("Convert %s -> %s", source_ext, dest_ext)
    
    c = Cassette.new(cfg)
    
    if source_ext == ".wav"
        c.add_from_wav(source_file)
    end
    elsif source_ext == ".cas"
        c.add_from_cas(source_file)
    end
    elsif source_ext == ".bas"
        c.add_from_bas(source_file)
    else
        raise RuntimeError # Should never happen
    end
    
    c.print_debug_info()
    
    if dest_ext == ".wav"
        c.write_wave(destination_file)
    end
    elsif dest_ext == ".cas"
        c.write_cas(destination_file)
    end
    elsif dest_ext == ".bas"
        c.write_bas(destination_file)
    else
        raise RuntimeError # Should never happen
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
