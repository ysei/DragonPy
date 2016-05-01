# coding: utf-8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


from dragonpy.core.configs import BaseConfig


class TestCfg < BaseConfig
    """
    Default test config
    """
    RAM_START = 0x0000
    RAM_END = 0x7FFF
    
    ROM_START = 0x8000
    ROM_END = 0xFFFF
    
    RESET_VECTOR = 0xFFFE
    
    BUS_ADDR_AREAS = (
        (0xFFF2, 0xFFFE, "Interrupt vectors"),
    end
    )
    
    DEFAULT_ROMS = nil
    
    def initialize (cfg_dict)
        
        super(TestCfg, self).__init__(cfg_dict)
    end
end
