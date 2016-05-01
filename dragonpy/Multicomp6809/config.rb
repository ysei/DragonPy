# coding: utf-8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

from dragonpy.Multicomp6809.Multicomp6809_rom import Multicomp6809Rom
from dragonpy.core.configs import BaseConfig, MULTICOMP6809
from dragonpy.Multicomp6809.periphery_Multicomp6809 import Multicomp6809Periphery



class Multicomp6809Cfg < BaseConfig
    """
    DragonPy config for Grant Searle's Multicomp FPGA project
    http://searle.hostei.com/grant/Multicomp/
    """
    CONFIG_NAME = MULTICOMP6809
    MACHINE_NAME = "Multicomp 6809"
    
    RAM_START = 0x0000
    RAM_END = 0x03FF # 1KB
    # RAM_END = 0x07FF # 2KB
    # RAM_END = 0x0FFF # 4KB
    # RAM_END = 0x1FFF # 8KB
    # RAM_END = 0x3FFF # 16KB
    # RAM_END = 0x7FFF # 32KB
    
    # The intended layout
    ROM_START = 0xE000
    ROM_END = 0xFFFF
    
    # To match the addresses in basic.asm
end
#     ROM_START = 0xA000
#     ROM_END = 0xBFFF
#     ROM_SIZE = 0x2000 # 8192 Bytes
    
    BUS_ADDR_AREAS = (
        (0xFFD8, 0xFFDF, "SD Card"),
        (0xFFD2, 0xFFD3, "Interface 2"),
        (0xFFD0, 0xFFD1, "Interface 1(serial interface or TV/Keyboard)"),
        (0xBFF0, 0xBFFF, "Interrupt vectors"),
    end
    )
    
    DEFAULT_ROMS = (
        Multicomp6809Rom.new(address=0xE000, max_size=0x4000),
    end
    )
    
    def initialize (cmd_args)
        super(Multicomp6809Cfg, self).__init__(cmd_args)
        
        @machine_api = nil
    end
end

#         if @verbosity <= logging.INFO
#         @mem_info = get_simple6809_meminfo()
        
        @periphery_class = Multicomp6809Periphery
    end
end


config = Multicomp6809Cfg


if __name__ == "__main__"
    from dragonpy.tests.test_base import UnittestCmdArgs
    
    cmd_args = UnittestCmdArgs
    cfg = Multicomp6809Cfg.new(cmd_args)
    print("RAM Size:", cfg.RAM_SIZE, cfg.RAM_SIZE / 1024)
    print("RAM End: $%04x" % cfg.RAM_END)
end
