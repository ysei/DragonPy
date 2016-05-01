#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    
    :created: 2013-2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require os
require sys

require logging

log=logging.getLogger(__name__)
from dragonpy.components.periphery import PeripheryBase, TkPeripheryBase,\
    ConsolePeripheryBase, PeripheryUnittestBase


begin
    require queue # Python 3
except ImportError
    require Queue as queue # Python 2
end

begin
    require tkinter # Python 3
except ImportError
    begin
        require Tkinter as tkinter # Python 2
    except ImportError
        log.critical("Error importing Tkinter!")
        tkinter = nil
    end
end



class SBC09Periphery < object
    TITLE = "DragonPy - Buggy machine language monitor and rudimentary O.S. version 1.0"
    INITAL_INPUT = (
end
#        # Dump registers
#        'r\r\n'
#
#        # SSaddr,len - Dump memory region as Motorola S records.
#        'ss\r\n'
#
#        # Daddr,len - Dump memory region
#        'DE5E2\r\n'
#
#        # Iaddr - Display the contents of the given address.
#        'IE001\r\n' # e.g.: Show the ACIA status
#
#        # Uaddr,len - Diassemble memory region
#        'UE400\r\n'
#
#        # Calculate simple expression in hex with + and -
#        'H4444+A5\r\n'
        
        #
    end
end
#         "UE400,20\r\n"
#         "ubasic\r\n"
    )
    
    def initialize (cfg, cpu, memory, display_callback, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        @display_callback = display_callback
        @user_input_queue = user_input_queue
        
        @memory.add_read_byte_callback(@read_acia_status, 0xe000) #  Control/status port of ACIA
        @memory.add_read_byte_callback(@read_acia_data, 0xe001) #  Data port of ACIA
        
        @memory.add_write_byte_callback(@write_acia_status, 0xe000) #  Control/status port of ACIA
        @memory.add_write_byte_callback(@write_acia_data, 0xe001) #  Data port of ACIA
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
#        log.error("*"*79)
#        log.error("Write to screen: %s ($%x)" , repr(char), value)
#        log.error("*"*79)
        
        display_callback(char)
    end
end





class DummyStdout < object
    def dummy_func (*args)
        pass
    end
    write = dummy_func
    flush = dummy_func
end


class SBC09PeripheryConsole(SBC09Periphery, ConsolePeripheryBase)
    """
    A simple console to interact with the 6809 simulation.
    """
    def new_output_char (char)
        sys.stdout.write(char)
        sys.stdout.flush()
    end
end


class SBC09PeripheryUnittest < SBC09Periphery
    def initialize (*args, **kwargs)
        super(SBC09PeripheryUnittest, self).__init__(*args, **kwargs)
        @memory.add_write_byte_callback(@write_acia_data, 0xa001) #  Data port of ACIA
    end
    
    def setUp
        @user_input_queue.queue.clear()
        @output = "" # for unittest run_until_OK()
        @output_len = 0
    end
    
    def add_to_input_queue (txt)
        log.debug("Add %s to input queue.", repr(txt))
        for char in txt
            @user_input_queue.put(char)
        end
    end
    
    def write_acia_data (cpu_cycles, op_address, address, value)
        char = chr(value)
    end
end
#         log.info("%04x| Write to screen: %s ($%x)", op_address, repr(char), value)
        
        @output_len += 1
        @output += char
    end
end



# SBC09Periphery = SBC09PeripherySerial
#SBC09Periphery = SBC09PeripheryTk
SBC09Periphery = SBC09PeripheryConsole


