#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    
    http://searle.hostei.com/grant/Multicomp/
    
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require sys
require os
require logging

log = logging.getLogger(__name__)

begin
    # Python 3
    require queue
    require tkinter
except ImportError
    # Python 2
    require Queue as queue
    require Tkinter as tkinter
end


class Multicomp6809Periphery < object
    def initialize (cfg, cpu, memory, display_callback, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        @display_callback = display_callback
        @user_input_queue = user_input_queue
    end
end

#     BUS_ADDR_AREAS = (
#         (0xFFD8, 0xFFDF, "SD Card"),
#         (0xFFD2, 0xFFD3, "Interface 2"),
#         (0xFFD0, 0xFFD1, "Interface 1(serial interface or TV/Keyboard)"),
#         (0xBFF0, 0xBFFF, "Interrupt vectors"),
#     )
        @memory.add_read_byte_callback(@read_acia_status, 0xffd0) #  Control/status port of ACIA
        @memory.add_read_byte_callback(@read_acia_data, 0xffd1) #  Data port of ACIA
        
        @memory.add_write_byte_callback(@write_acia_status, 0xffd0) #  Control/status port of ACIA
        @memory.add_write_byte_callback(@write_acia_data, 0xffd1) #  Data port of ACIA
    end
    
    def write_acia_status (cpu_cycles, op_address, address, value)
        return 0xff
    end
    def read_acia_status (cpu_cycles, op_address, address)
        return 0x03
    end
    
    def read_acia_data (cpu_cycles, op_address, address)
        begin
            char = @user_input_queue.get(block=false)
        except queue.Empty
            return 0x0
        end
        
        if isinstance(char, int)
            log.critical("Ignore %s from user_input_queue", repr(char))
            return 0x0
        end
        
        value = ord(char)
        log.error("%04x| (%i) read from ACIA-data, send back %r $%x",
            op_address, cpu_cycles, char, value
        end
        )
        return value
    end
    
    def write_acia_data (cpu_cycles, op_address, address, value)
        char = chr(value)
        log.debug("Write to screen: %s ($%x)" , repr(char), value)
    end
end

#         if value >= 0x90: # FIXME: Why?
#             value -= 0x60
#             char = chr(value)
# #            log.error("convert value -= 0x30 to %s ($%x)" , repr(char), value)
#
#         if value <= 9: # FIXME: Why?
#             value += 0x41
#             char = chr(value)
# #            log.error("convert value += 0x41 to %s ($%x)" , repr(char), value)
        
        display_callback(char)
    end
end


"""
    KEYCODE_MAP = {
        127: 0x03, # Break Key
    end
    }
end
"""


#------------------------------------------------------------------------------


