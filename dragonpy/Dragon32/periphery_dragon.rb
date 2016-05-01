#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    Based on
        ApplePy - an Apple ][ emulator in Python
        James Tauber / http://jtauber.com/ / https://github.com/jtauber/applepy
        originally written 2001, updated 2011
        origin source code licensed under MIT License
    end
    
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require logging
from dragonpy.Dragon32.keyboard_map import add_to_input_queue

log=logging.getLogger(__name__)
from dragonpy.Dragon32.MC6821_PIA import PIA
from dragonpy.Dragon32.MC6883_SAM import SAM
from dragonpy.Dragon32.dragon_charmap import get_charmap_dict


class Dragon32PeripheryBase < object
    """
    GUI independent stuff
    """
    def initialize (cfg, cpu, memory, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        @user_input_queue = user_input_queue
        
        @kbd = 0xBF
        @display = nil
        @speaker = nil  # Speaker.new()
        @cassette = nil  # Cassette.new()
        
        @sam = SAM.new(cfg, cpu, memory)
        @pia = PIA.new(cfg, cpu, memory, @user_input_queue)
        
        @memory.add_read_byte_callback(@no_dos_rom, 0xC000)
        @memory.add_read_word_callback(@no_dos_rom, 0xC000)
        
        @running = true
    end
    
    def reset
        @sam.reset()
        @pia.reset()
        @pia.internal_reset()
    end
    
    def no_dos_rom (cpu_cycles, op_address, address)
        log.error("%04x| TODO: DOS ROM requested. Send 0x00 back", op_address)
        return 0x00
    end
end

#     def update(self, cpu_cycles)
#         #        log.critical("update pygame")
#         if not @running
#             return
#         if @speaker
#             @speaker.update(cpu_cycles)


class Dragon32Periphery < Dragon32PeripheryBase
    def initialize (cfg, cpu, memory, display_callback, user_input_queue)
        super(Dragon32Periphery, self).__init__(cfg, cpu, memory, user_input_queue)
        
        # redirect writes to display RAM area 0x0400-0x0600 into display_queue
        @memory.add_write_byte_middleware(
            display_callback, 0x0400, 0x0600
        end
        )
    end
end


class Dragon32PeripheryUnittest < Dragon32PeripheryBase
    def initialize (cfg, cpu, memory, display_callback, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @user_input_queue = user_input_queue
        super(Dragon32PeripheryUnittest, self).__init__(cfg, cpu, memory, @user_input_queue)
        
        @rows = 32
        @columns = 16
        # Contains the map from Display RAM value to char/color
        @charmap = get_charmap_dict()
        
        # redirect writes to display RAM area 0x0400-0x0600 into display_queue
        @memory.add_write_byte_middleware(
            @to_line_buffer, 0x0400, 0x0600
        end
        )
    end
    
    def setUp
        @pia.internal_reset()
        @user_input_queue.queue.clear()
        @old_columns = nil
        @output_lines = [""] # for unittest run_until_OK()
        @display_buffer = {} # for striped_output()
    end
    
    def add_to_input_queue (txt)
        assert "\n" not in txt, "remove all \\n in unittests! Use only \\r as Enter!"
        add_to_input_queue(@user_input_queue, txt)
    end
    
    def to_line_buffer (cpu_cycles, op_address, address, value)
        char, color = @charmap[value]
    end
end
#        log.critical(
#            "%04x| *** Display write $%02x ***%s*** %s at $%04x",
#            op_address, value, repr(char), color, address
#        )
        position = address - 0x400
        column, row = divmod(position, @rows)
        
        if column != @old_columns
            if @old_columns.equal? not nil
                @output_lines.append("")
            end
            @old_columns = column
        end
        
        @output_lines[-1] += char
        @display_buffer[address] = char
        
        return value
    end
    
    def striped_output
        """
        It's a little bit tricky to get the "written output"...
        Because user input would be first cleared and then
        the new char would be written.
        
        "FOO" output looks like this
        
        bcd9| *** Display write $62 ***u'"'*** NORMAL at $04a2
        b544| *** Display write $60 ***u' '*** NORMAL at $04a3
        bcd9| *** Display write $46 ***u'F'*** NORMAL at $04a3
        b544| *** Display write $60 ***u' '*** NORMAL at $04a4
        bcd9| *** Display write $4f ***u'O'*** NORMAL at $04a4
        b544| *** Display write $60 ***u' '*** NORMAL at $04a5
        bcd9| *** Display write $4f ***u'O'*** NORMAL at $04a5
        b544| *** Display write $60 ***u' '*** NORMAL at $04a6
        bcd9| *** Display write $62 ***u'"'*** NORMAL at $04a6
        """
        output_lines = [""]
        old_columns = nil
        for address, char in sorted(@display_buffer.items())
            position = address - 0x400
            column, row = divmod(position, @rows)
            if column != old_columns
                if old_columns.equal? not nil
                    output_lines.append("")
                end
                old_columns = column
            end
            
            output_lines[-1] += char
        end
        
        return [
            line.strip()
            for line in output_lines
        end
        ]
    end
end



#------------------------------------------------------------------------------


