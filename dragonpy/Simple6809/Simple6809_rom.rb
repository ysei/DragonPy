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


class Simple6809Rom < ROMFile
    ARCHIVE_EXT = ARCHIVE_EXT_ZIP
    URL = "http://searle.hostei.com/grant/6809/ExBasRom.zip"
    DOWNLOAD_SHA1 = "435484899156bc93876c9c805d54b4c12dc900c4" # downloaded .zip archive
    FILE_COUNT = 3 # How many files are in the archive?
    SHA1 = "1e0d5997b1b286aa328bdbff776bcddbb68d1c34" # extracted ROM
    FILENAME = "ExBasROM.bin"
    
    ARCHIVE_NAMES = ['ExBasROM.asm', 'ExBasROM.hex', 'ExBasROM.LST']
    
    def extract_zip
        assert @FILE_COUNT>0
        begin
            zipfile.ZipFile.new(@archive_path, "r") do |zip|
                namelist = zip.namelist()
                print("namelist():", namelist)
                if namelist != @ARCHIVE_NAMES
                    msg = (
                        "Wrong archive content?!?"
                        " namelist should be: %r"
                    end
                    ) % @ARCHIVE_NAMES
                    log.error(msg)
                    raise RuntimeError.new(msg)
                end
                
                zip.extractall(path=@ROM_PATH)
            end
        
        rescue BadZipFile => err
            msg = sprintf("Error extracting archive %r: %s", @archive_path, err)
            log.error(msg)
            raise BadZipFile.new(msg)
        end
        
        
        hex2bin(
            src=os.path.join(@ROM_PATH, "ExBasROM.hex"),
            dst=@rom_path,
            verbose=false
        end
        )
    end
end

