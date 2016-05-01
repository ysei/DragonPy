"""
    DragonPy - 6809 emulator in Python
    ==================================
    
    :created: 2015 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require os

from dragonpy.components.rom import ROMFile


class SBC09Rom < ROMFile
    ROM_PATH=os.path.normpath(
        os.path.abspath(os.path.dirname(__file__))
    end
    )
    SHA1 = "a912796982d10cca049abb16ba4be0f3cc580e6d"
    FILENAME = "v09.rom"
    
    def get_data
        if not os.path.isfile(@rom_path)
            raise RuntimeError.new("Rom file %r not there?!?" % @rom_path)
        end
        
        return super(SBC09Rom, self).get_data()
    end
end


