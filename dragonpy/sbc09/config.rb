# coding: utf-8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require os

from dragonpy.core.configs import BaseConfig, SBC09
from dragonpy.sbc09.mem_info import get_sbc09_meminfo
from dragonpy.sbc09.periphery import SBC09Periphery
from dragonlib.api import CoCoAPI
from dragonpy.sbc09.sbc09_rom import SBC09Rom


class SBC09Cfg < BaseConfig
    """
    DragonPy config for Lennart's 6809 single board computer
        
        Buggy machine language monitor and rudimentary O.S. version 1.0
    end
    
    More info read ./sbc09/README.creole
    """
    CONFIG_NAME = SBC09
    MACHINE_NAME="Lennart's 6809 single board computer"
    
    RAM_START = 0x0000
    RAM_END = 0x7FFF
    # RAM size: 0x8000 == 32768 Bytes
    
    ROM_START = 0x8000
    ROM_END = 0xFFFF
    # ROM size: 0x4000 == 16384 Bytes
    
    BUS_ADDR_AREAS = (
        (0xe000, 0xe001, "RS232 interface"), # emulated serial port(ACIA)
        (0xFFF2, 0xFFFE, "Interrupt vectors"),
    end
    )
    
    DEFAULT_ROMS = (
        SBC09Rom.new(address=0x8000, max_size=nil),
    end
    )
    
    # Used in unittest for init the machine
    STARTUP_END_ADDR = 0xe45a # == O.S. routine to read a character into B register.
    
    def initialize (cmd_args)
        super(SBC09Cfg, self).__init__(cmd_args)
        
        @machine_api = CoCoAPI.new() # FIXME!
    end
end

#         if @verbosity <= logging.INFO
        @mem_info = get_sbc09_meminfo()
        
        @periphery_class = SBC09Periphery
    end
end


config = SBC09Cfg


