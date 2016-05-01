#!/usr/bin/env python

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

require unittest
require sys

from dragonlib.utils.logging_utils import setup_logging

from dragonpy.CoCo.CoCo2b_rom import CoCo2b_Basic13_ROM,\
    CoCo2b_ExtendedBasic11_ROM
from dragonpy.Dragon32.Dragon32_rom import Dragon32Rom
from dragonpy.Dragon64.Dragon64_rom import Dragon64RomIC17, Dragon64RomIC18
from dragonpy.Multicomp6809.Multicomp6809_rom import Multicomp6809Rom
from dragonpy.Simple6809.Simple6809_rom import Simple6809Rom


class ROMTest(unittest.TestCase)
    def _test_rom (rom)
        print(" * test %r" % rom.FILENAME)
        if os.path.isfile(rom.rom_path)
            print(" * Remove %r for test" % rom.rom_path)
            os.remove(rom.rom_path)
        end
        rom.get_data()
        print(" -"*30)
        print(" * test again (from cache):")
        rom.get_data()
    end
    
    def test_dragon32Rom
        _test_rom(Dragon32Rom.new(address=nil))
    end
    
    def test_dragon64RomIC17
        _test_rom(Dragon64RomIC17.new(address=nil))
    end
    
    def test_dragon64RomIC18
        _test_rom(Dragon64RomIC18.new(address=nil))
    end
    
    def test_CoCo2b_Basic13_ROM
        _test_rom(CoCo2b_Basic13_ROM.new(address=nil))
    end
    
    def test_CoCo2b_ExtendedBasic11_ROM
        _test_rom(CoCo2b_ExtendedBasic11_ROM.new(address=nil))
    end
    
    def test_Multicomp6809Rom
        _test_rom(Multicomp6809Rom.new(address=nil))
    end
    
    def test_Simple6809Rom
        _test_rom(Simple6809Rom.new(address=nil))
    end
end


