#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy
    ========
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require os
require sys

require logging

log=logging.getLogger(__name__)
from dragonpy.components.periphery import PeripheryBase
from dragonpy.vectrex.MOS6522 import MOS6522VIA


class VectrexPeripheryBase < PeripheryBase
    """
    GUI independent stuff
    """
    def initialize (cfg, memory, user_input_queue)
        super(VectrexPeripheryBase, self).__init__(cfg, memory, user_input_queue)
        
        @via = MOS6522VIA.new(cfg, memory)
        
        # $0000 - $7FFF Cartridge ROM
        @memory.add_read_byte_callback(@cartridge_rom, 0xC000)
        @memory.add_read_word_callback(@cartridge_rom, 0xC000)
        
        @running = true
    end
    
    def cartridge_rom (cpu_cycles, op_address, address)
        log.error("%04x| TODO: $0000 - $7FFF Cartridge ROM. Send 0x00 back", op_address)
        return 0x00
    end
end

#     def update(self, cpu_cycles)
#         #        log.critical("update pygame")
#         if not @running
#             return
#         if @speaker
#             @speaker.update(cpu_cycles)


class VectrexPeriphery < VectrexPeripheryBase
    def initialize (cfg, memory, display_queue, user_input_queue)
        super(VectrexPeriphery, self).__init__(cfg, memory, user_input_queue)
        
        # redirect writes to display RAM area 0x0400-0x0600 into display_queue
        #DragonDisplayOutputHandler.new(display_queue, memory)
    end
end

#------------------------------------------------------------------------------


