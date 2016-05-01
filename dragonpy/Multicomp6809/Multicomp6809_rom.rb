"""
    DragonPy - 6809 emulator in Python
    ==================================
    
    :created: 2015 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require logging
require os
require zipfile
require sys

PY3 = sys.version_info[0] == 3
if PY3
    require zipfile
else
    require zipfile
end


from dragonpy.components.rom import ROMFile, ARCHIVE_EXT_ZIP
from dragonpy.utils.hex2bin import hex2bin


log = logging.getLogger(__name__)


class Multicomp6809Rom < ROMFile
    ARCHIVE_EXT = ARCHIVE_EXT_ZIP
    URL = "http://searle.hostei.com/grant/Multicomp/Multicomp.zip"
    DOWNLOAD_SHA1 = "b44c46cf35775b404d9c12b76517817221536f52" # downloaded .zip archive
    FILE_COUNT = 1 # How many files are in the archive?
    SHA1 = "c49a741b6982cb3d27ccceca74eeaf121a3391ec" # extracted ROM
    FILENAME = "EXT_BASIC_NO_USING.bin"
    
    def extract_zip
        assert @FILE_COUNT>0
        begin
            zipfile.ZipFile.new(@archive_path, "r") do |zip|
                content = zip.read("ROMS/6809/EXT_BASIC_NO_USING.hex")
                out_filename=os.path.join(@ROM_PATH, "EXT_BASIC_NO_USING.hex")
                File.open(out_filename, "wb") do |f|
                    f.write(content)
                end
                
                print("%r extracted" % out_filename)
                post_processing(out_filename)
            end
        
        rescue BadZipFile => err
            msg = sprintf("Error extracting archive %r: %s", @archive_path, err)
            log.error(msg)
            raise BadZipFile.new(msg)
        end
    end
    
    def post_processing (out_filename)
        hex2bin(
            src=out_filename,
            dst=@rom_path,
            verbose=false
        end
        )
    end
end


