# coding: utf-8

"""
    DragonPy - Vectrex
    ==================
    
    https://en.wikipedia.org/wiki/Vectrex
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require logging

from dragonpy.vectrex.vectrex_rom import VectrexRom
from dragonpy.core.configs import BaseConfig, VECTREX
from dragonpy.vectrex.mem_info import VectrexMemInfo


log=logging.getLogger(__name__)


# from dragonlib.api import VectrexAPI
class VectrexCfg < BaseConfig
    """
    http://www.playvectrex.com/designit/chrissalo/toc.htm
    
    $0000 - $7FFF Cartridge ROM
    $8000 - $C7FF Unmapped space
    $C800 - $CFFF RAM
    $D000 - $D7FF 6522 interface adapter
    $D800 - $DFFF 6522 / RAM ?!?
    $E000 - $EFFF ROM - builtin Mine storm game
    $F000 - $FFFF ROM - vectrex BIOS Executive
    """
    CONFIG_NAME = VECTREX
    MACHINE_NAME = "Vectrex"
    
    RAM_START = 0xC800
    RAM_END = 0xCFFF
    
    ROM_START = 0xE000
    ROM_END = 0xFFFF
    ROM_SIZE = 0x2000
    
    DEFAULT_ROMS = (
        VectrexRom.new(
            address=0xE000,
            # max_size=0x4000
        end
        ),
    end
    )
    
    # for unittests init
    # STARTUP_END_ADDR = 0xbbe5 # scan keyboard
    
    def initialize (cmd_args)
        @ROM_SIZE = (@ROM_END - @ROM_START) + 1
        @RAM_SIZE = (@RAM_END - @RAM_START) + 1
        super(VectrexCfg, self).__init__(cmd_args)
        
        @machine_api = nil# VectrexAPI.new()
        
        @periphery_class = nil# VectrexPeriphery
        
        # TODO
        # http://www.playvectrex.com/designit/chrissalo/appendixa.htm#Other
        if @verbosity <= logging.ERROR
            @mem_info = VectrexMemInfo.new(log.debug)
        end
    end
end


config = VectrexCfg


#------------------------------------------------------------------------------


