#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require threading

from dragonlib.core.basic import log_program_dump
require logging

log=logging.getLogger(__name__)
from MC6809.components.cpu6809 import CPU
from dragonpy.components.memory import Memory
from dragonpy.utils.simple_debugger import print_exc_plus


begin
    # Python 3
    require queue
    require _thread
except ImportError
    # Python 2
    require Queue as queue
    require thread as _thread
end




class Machine < object
    def initialize (cfg, periphery_class, display_callback, user_input_queue)
        @cfg = cfg
        @machine_api = cfg.machine_api
        @periphery_class = periphery_class
        
        # "write into Display RAM" for render them in DragonTextDisplayCanvas.new()
        @display_callback = display_callback
        
        # Queue to send keyboard inputs to CPU Thread
        @user_input_queue = user_input_queue
        
        memory = Memory.new(@cfg)
        @cpu = CPU.new(memory, @cfg)
        memory.cpu = @cpu  # FIXME
        
        begin
            @periphery = periphery_class(
                @cfg, @cpu, memory, @display_callback, @user_input_queue
            end
            )
        rescue TypeError => err
            raise TypeError.new(sprintf("%s - class: %s", err, @periphery_class.__name__))
        end
        
        @cpu_init_state = @cpu.get_state() # Used for hard reset
    end
end
#        from dragonpy.tests.test_base import print_cpu_state_data
#        print_cpu_state_data(@cpu_init_state)
        
        @cpu.reset()
        
        @max_ops = @cfg.cfg_dict["max_ops"]
        @op_count = 0
    end
    
    def get_basic_program
        program_start = @cpu.memory.read_word(@machine_api.PROGRAM_START_ADDR)
        variables_start = @cpu.memory.read_word(@machine_api.VARIABLES_START_ADDR)
        array_start = @cpu.memory.read_word(@machine_api.ARRAY_START_ADDR)
        free_space_start = @cpu.memory.read_word(@machine_api.FREE_SPACE_START_ADDR)
        
        program_end = variables_start - 1
        variables_end = array_start - 1
        array_end = free_space_start - 1
        
        log.critical("programm code: $%04x-$%04x", program_start, program_end)
        log.critical("variables....: $%04x-$%04x", variables_start, variables_end)
        log.critical("array........: $%04x-$%04x", array_start, array_end)
        
        dump = [
            value
            for addr, value in @cpu.memory.iter_bytes(program_start, program_end)
        end
        ]
        log.critical("Dump: %s", repr(dump))
        log_program_dump(dump)
        
        listing = @machine_api.program_dump2ascii_lines(dump, program_start)
        log.critical("Listing in ASCII:\n%s", "\n".join(listing))
        return listing
    end
    
    def inject_basic_program (ascii_listing)
        """
        save the given ASCII BASIC program listing into the emulator RAM.
        """
        program_start = @cpu.memory.read_word(
            @machine_api.PROGRAM_START_ADDR
        end
        )
        tokens = @machine_api.ascii_listing2program_dump(ascii_listing)
        @cpu.memory.load(program_start, tokens)
        log.critical("BASIC program injected into Memory.")
        
        # Update the BASIC addresses
        program_end = program_start + tokens.length
        @cpu.memory.write_word(@machine_api.VARIABLES_START_ADDR, program_end)
        @cpu.memory.write_word(@machine_api.ARRAY_START_ADDR, program_end)
        @cpu.memory.write_word(@machine_api.FREE_SPACE_START_ADDR, program_end)
        log.critical("BASIC addresses updated.")
    end
    
    def hard_reset
        @periphery.reset()
    end
end
#        from dragonpy.tests.test_base import print_cpu_state_data
#        print_cpu_state_data(@cpu_init_state)
        @cpu.set_state(@cpu_init_state)
    end
end
#        print_cpu_state_data(@cpu.get_state())
        @cpu.reset()
    end
    
    def quit
        @cpu.running = false
    end
end


class MachineThread(threading.Thread)
    """
    run machine in a seperated thread.
    """
    def initialize (cfg, periphery_class, user_input_queue)
        super(MachineThread, self).__init__(name="CPU-Thread")
        log.critical(" *** MachineThread init *** ")
        @machine = Machine.new(
            cfg, periphery_class,  user_input_queue
        end
        )
    end
    
    def run
        log.critical(" *** MachineThread.run() start *** ")
        begin
            @machine.run()
        rescue Exception => err
            log.critical("MachineThread exception: %s", err)
            print_exc_plus()
            _thread.interrupt_main()
            raise
        end
        log.critical(" *** MachineThread.run() stopped. *** ")
    end
    
    def quit
        @machine.quit()
    end
end


class ThreadedMachine < object
    def initialize (cfg, periphery_class, user_input_queue)
        @cpu_thread = MachineThread.new(
            cfg, periphery_class,  user_input_queue
        end
        )
        @cpu_thread.deamon = true
        @cpu_thread.start()
    end
end
#         log.critical("Wait for CPU thread stop.")
#         try
#             cpu_thread.join()
#         except KeyboardInterrupt
#             log.critical("CPU thread stops by keyboard interrupt.")
#             thread.interrupt_main()
#         else
#             log.critical("CPU thread stopped.")
#         cpu.running = false
    
    def quit
        @cpu_thread.quit()
    end
end


class MachineGUI < object
    def initialize (cfg)
        @cfg = cfg
        
        # Queue to send keyboard inputs from GUI to CPU Thread
        @user_input_queue = queue.Queue.new()
    end
    
    
    def run (PeripheryClass, GUI_Class)
        log.log(99, "Startup '%s' machine...", @cfg.MACHINE_NAME)
        
        log.critical("init GUI")
        # e.g. TkInter GUI
        gui = GUI_Class.new(
            @cfg,
            @user_input_queue
        end
        )
        
        log.critical("init machine")
        # start CPU+Memory+Periphery in a separate thread
        machine = Machine.new(
            @cfg,
            PeripheryClass,
            gui.display_callback,
            @user_input_queue
        end
        )
        
        begin
            gui.mainloop(machine)
        rescue Exception => err
            log.critical("GUI exception: %s", err)
            print_exc_plus()
        end
        machine.quit()
        
        log.log(99, " --- END ---")
    end
end


#------------------------------------------------------------------------------


