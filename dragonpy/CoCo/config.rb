# coding: utf-8

"""
    CoCo config
    ================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require logging

from dragonlib.api import CoCoAPI
from dragonpy.CoCo.CoCo2b_rom import CoCo2b_Basic13_ROM,\
    CoCo2b_ExtendedBasic11_ROM

from dragonpy.CoCo.mem_info import get_coco_meminfo
from dragonpy.Dragon32.config import Dragon32Cfg
from dragonpy.Dragon32.keyboard_map import get_coco_keymatrix_pia_result
from dragonpy.core.configs import COCO2B


log=logging.getLogger(__name__)


class CoCo2bCfg < Dragon32Cfg
    CONFIG_NAME = COCO2B
    MACHINE_NAME = "CoCo2b"
    
    # How does the keyboard polling routine starts with?
    PIA0B_KEYBOARD_START = 0xfe
    
    RAM_START = 0x0000
    
    # 1KB RAM.equal? not runnable and raise a error
    # 2-8 KB - BASIC Interpreter will be initialized. But every
    #          statement will end_ with a OM ERROR.new(Out of Memory)
    # 16 KB - Is usable
end

#     RAM_END = 0x03FF # 1KB
#     RAM_END = 0x07FF # 2KB # BASIC will always raise a OM ERROR!
#     RAM_END = 0x0FFF # 4KB # BASIC will always raise a OM ERROR!
#     RAM_END = 0x1FFF # 8KB # BASIC will always raise a OM ERROR!
#     RAM_END = 0x3FFF # 16KB # usable
    RAM_END = 0x7FFF # 32KB
    
    ROM_START = 0x8000
    ROM_END = 0xFFFF
    
    """
    EXTENDED COLOR BASIC
    
    $a000-$bfff - 'bas13.rom'    - size: $1fff(dez.: 8191) Bytes
    $8000-$9fff - 'extbas11.rom' - size: $1fff(dez.: 8191) Bytes
    """
    ROM_START = 0x8000
    DEFAULT_ROMS = (
        CoCo2b_ExtendedBasic11_ROM.new(address=0x8000, max_size=0x4000),
        CoCo2b_Basic13_ROM.new(address=0xA000, max_size=0x4000),
    end
    )
    
    def initialize (cmd_args)
        super(CoCo2bCfg, self).__init__(cmd_args)
        
        @machine_api = CoCoAPI.new()
        
        if @verbosity <= logging.ERROR
            @mem_info = get_coco_meminfo()
        end
        
        @periphery_class = nil# Dragon32Periphery
        
        @memory_byte_middlewares = {
            # (start_addr, end_addr): (read_func, write_func)
            # (0x0152, 0x0159): (nil, @keyboard_matrix_state),
            # (0x0115, 0x0119): (@rnd_seed_read, @rnd_seed_write),
            # (0x0112, 0x0113): (@timer_value_read, @timer_value_write),
        end
        }
        @memory_word_middlewares = {
            # (0x0019, 0x0027): (nil, @basic_addresses_write),
            # (0x0112, 0x0113): (@timer_value_read_word, @timer_value_write_word),
        end
        }
    end
    
    def rnd_seed_read (cycles, last_op_address, address, byte)
        log.critical("%04x| read $%02x RND.new() seed from: $%04x", last_op_address, byte, address)
        return byte
    end
    
    def rnd_seed_write (cycles, last_op_address, address, byte)
        log.critical("%04x| write $%02x RND.new() seed to: $%04x", last_op_address, byte, address)
        return byte
    end
    
    def basic_addresses_write (cycles, last_op_address, address, word)
        """
        0113 0019 TXTTAB RMB 2 *PV BEGINNING OF BASIC PROGRAM
        0114 001B VARTAB RMB 2 *PV START OF VARIABLES
        0115 001D ARYTAB RMB 2 *PV START OF ARRAYS
        0116 001F ARYEND RMB 2 *PV END OF ARRAYS.new(+1)
        0117 0021 FRETOP RMB 2 *PV START OF STRING STORAGE.new(TOP OF FREE RAM)
        0118 0023 STRTAB RMB 2 *PV START OF STRING VARIABLES
        0119 0025 FRESPC RMB 2 UTILITY STRING POINTER
        0120 0027 MEMSIZ RMB 2 *PV TOP OF STRING SPACE
        """
        log.critical("%04x| write $%04x to $%04x", last_op_address, word, address)
        return word
    end
    
    def pia_keymatrix_result (inkey, pia0b)
        return get_coco_keymatrix_pia_result(inkey, pia0b)
    end
end


config = CoCo2bCfg


#------------------------------------------------------------------------------


