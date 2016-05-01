# encoding:utf8

"""
    DragonPy - Base Periphery
    =========================
    
    
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__
require six
xrange = six.moves.xrange

require sys
require threading
require time

begin
    # Python 3
    require queue
    require _thread
end
#    import http.client
except ImportError
    # Python 2
    require Queue as queue
    require thread as _thread
end
#    import httplib

require logging

log = logging.getLogger(__name__)
from dragonpy.utils import pager



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



class PeripheryBase < object
    INITAL_INPUT = nil # For quick test
    
    def initialize (cfg, cpu, memory, display_queue=nil, user_input_queue=nil)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        @user_input_queue = user_input_queue
        @display_queue = display_queue # Buffer for output from CPU
        
        @running = true
        @update_time = 0.1
        @last_cpu_cycle_update = time.time()
        
        if @INITAL_INPUT.equal? not nil
            add_to_input_queue(@INITAL_INPUT)
        end
    end
    
    def add_to_input_queue (txt)
        log.debug("Add %s to input queue.", repr(txt))
        for char in txt
            @user_input_queue.put(char)
        end
    end
    
    def exit
        log.critical("Exit called in periphery.")
        @running = false
    end
    
    def mainloop (cpu)
        cpu.reset()
        max_ops = @cfg.cfg_dict["max_ops"]
        if max_ops
            log.critical("Running only %i ops!", max_ops)
            for __ in xrange(max_ops)
                cpu.get_and_call_next_op()
                if not(@periphery.running and @cpu.running)
                    break
                end
            end
            log.critical("Quit CPU after given 'max_ops' %i ops.", max_ops)
        else
            while @periphery.running and @cpu.running
                cpu.get_and_call_next_op()
            end
        end
        
        cpu.quit()
        @periphery.exit()
    end
    
    def add_output (text)
        raise NotImplementedError
    end
    
    def write_acia_status (cpu_cycles, op_address, address, value)
        raise NotImplementedError
    end
    def read_acia_status (cpu_cycles, op_address, address)
        raise NotImplementedError
    end
    
    def read_acia_data (cpu_cycles, op_address, address)
        raise NotImplementedError
    end
    def write_acia_data (cpu_cycles, op_address, address, value)
        raise NotImplementedError
    end
end


###############################################################################
# TKinter Base ################################################################
###############################################################################


class TkPeripheryBase < PeripheryBase
    TITLE = "DragonPy - Base Tkinter Periphery"
    GEOMETRY = "+500+300"
    KEYCODE_MAP = {}
    ESC_KEYCODE = "\x03" # What keycode to send, if escape Key pressed?
    
    def initialize (cfg)
        super(TkPeripheryBase, self).__init__(cfg)
        assert tkinter.equal? not nil, "ERROR: Tkinter.equal? not available!"
        @root = tkinter.Tk.new()
        
        @root.title(@TITLE)
    end
end
#         @root.geometry() # '640x480+500+300') # X*Y + x/y-offset
        @root.geometry(@GEOMETRY) # Change initial position
        
        # http://www.tutorialspoint.com/python/tk_text.htm
        @text = tkinter.Text.new(
            @root,
            height=20, width=80,
            state=tkinter.DISABLED # FIXME: make textbox "read-only"
        end
        )
        scollbar = tkinter.Scrollbar.new(@root)
        scollbar.config(command=@text.yview)
        
        @text.config(
            background="#08ff08", # nearly green
            foreground="#004100", # nearly black
            font=('courie/, 11, /bold'),
        end
    end
end
#            yscrollcommand=scollbar.set, # FIXME
        )
        
        scollbar.pack(side=tkinter.RIGHT, fill=tkinter.Y)
        @text.pack(side=tkinter.LEFT, fill=tkinter.Y)
        
        @root.bind("<Return>", @event_return)
        @root.bind("<Escape>", @from_console_break)
        @root.bind('<Control-c>', @copy_to_clipboard)
        @root.bind("<Key>", @event_key_pressed)
        @root.bind("<Destroy>", @destroy)
        
        @root.update()
        @update_thread = nil
    end
    
    def event_return (event)
end
#        log.critical("ENTER: add \\n")
        @user_input_queue.put("\n")
    end
    
    def from_console_break (event)
        log.critical("from_console_break(): Add %r to input queue", @ESC_KEYCODE)
        @user_input_queue.put(@ESC_KEYCODE)
    end
    
    def copy_to_clipboard (event)
        log.critical("Copy to clipboard")
        text = @text.get("1.0", tkinter.END)
        print(text)
        @root.clipboard_clear()
        @root.clipboard_append(text)
    end
    
    def event_key_pressed (event)
        keycode = event.keycode
        char = event.char
        log.critical("keycode %s - char %s", keycode, repr(char))
        if char
            char = char.upper()
        end
        elsif keycode in @KEYCODE_MAP
            char = chr(@KEYCODE_MAP[keycode])
            log.critical("keycode %s translated to: %s", keycode, repr(char))
        else
            log.critical("Ignore input, doesn't send to CPU.")
            return
        end
        
        log.debug("Send %s", repr(char))
        @user_input_queue.put(char)
    end
    
    def exit (msg)
        log.critical(msg)
        @root.quit()
        super(TkPeripheryBase, self).exit()
    end
    
    def destroy (event=nil)
        exit("Tk window closed.")
    end
    
    STATE = 0
    LAST_INPUT = ""
    def write_acia_data (cpu_cycles, op_address, address, value)
        log.debug(sprintf("%04x| (%i) write to ACIA-data value: $%x(dez.: %i) ASCII: %r", 
            op_address, cpu_cycles, value, value, chr(value)
        end
        ))
        if value == 0x8: # Backspace
            @text.config(state=tkinter.NORMAL)
            # delete last character
            @text.delete("%s - 1 chars" % tkinter.INSERT, tkinter.INSERT)
            @text.config(state=tkinter.DISABLED) # FIXME: make textbox "read-only"
            return
        end
        
        super(TkPeripheryBase, self).write_acia_data(cpu_cycles, op_address, address, value)
    end
    
    def _new_output_char (char)
        """ insert in text field """
        @text.config(state=tkinter.NORMAL)
        @text.insert("end_", char)
        @text.see("end_")
        @text.config(state=tkinter.DISABLED)
    end
    
    def add_input_interval (cpu_process)
        if not cpu_process.is_alive()
            exit("CPU process.equal? not alive.")
        end
        
        while true
            begin
                char = @display_queue.get(block=false)
            except queue.Empty
                break
            else
                _new_output_char(char)
            end
        end
        
        @root.after(100, @add_input_interval, cpu_process)
    end
    
    def mainloop (cpu_process)
        log.critical("Tk mainloop started.")
        add_input_interval(cpu_process)
        @root.mainloop()
        log.critical("Tk mainloop stopped.")
    end
end


###############################################################################
# Console Base ################################################################
###############################################################################


class InputPollThread(threading.Thread)
    def initialize (cpu_process, user_input_queue)
        super(InputPollThread, self).__init__(name="InputThread")
        @cpu_process = cpu_process
        @user_input_queue = user_input_queue
        check_cpu_interval(cpu_process)
    end
    
    def check_cpu_interval (cpu_process)
        """
        work-a-round for blocking input
        """
        begin
    end
end
#            log.critical("check_cpu_interval()")
            if not cpu_process.is_alive()
                log.critical("raise SystemExit, because CPU.equal? not alive.")
                _thread.interrupt_main()
                raise SystemExit.new("Kill pager.getch()")
            end
        except KeyboardInterrupt
            _thread.interrupt_main()
        else
            t = threading.Timer.new(1.0, @check_cpu_interval, args=[cpu_process])
            t.start()
        end
    end
    
    def _run
        while @cpu_process.is_alive()
            char = pager.getch() # Important: It blocks while waiting for a input
            if char == "\n"
                @user_input_queue.put("\r")
            end
            
            char = char.upper()
            @user_input_queue.put(char)
        end
    end
    
    def run
        log.critical("InputPollThread.run() start")
        begin
            _run()
        except KeyboardInterrupt
            _thread.interrupt_main()
        end
        log.critical("InputPollThread.run() ends, because CPU not alive anymore.")
    end
end


class ConsolePeripheryBase < PeripheryBase
    def new_output_char (char)
        sys.stdout.write(char)
        sys.stdout.flush()
    end
    
    def mainloop (cpu_process)
        log.critical("ConsolePeripheryBase.mainloop() start")
        input_thread = InputPollThread.new(cpu_process, @user_input_queue)
        input_thread.deamon = true
        input_thread.start()
    end
end


###############################################################################
# Unittest Base ###############################################################
###############################################################################


class PeripheryUnittestBase < object
    def initialize (cfg, cpu, memory, display_queue, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @display_queue = display_queue
        @user_input_queue = user_input_queue
    end
    
    def setUp
        @user_input_queue.queue.clear()
        @display_queue.queue.clear()
        @old_columns = nil
        @output_lines = [""] # for unittest run_until_OK()
        @display_buffer = {} # for striped_output()
    end
    
    def _new_output_char (char)
end
#        sys.stdout.write(char)
#        sys.stdout.flush()
        @out_buffer += char
        if char == "\n"
            @output_lines.append(@out_buffer)
            @out_buffer = ""
        end
    end
    
    def write_acia_data (cpu_cycles, op_address, address, value)
        raise
        super(PeripheryUnittestBase, self).write_acia_data(cpu_cycles, op_address, address, value)
        
        while true
            begin
                char = @display_queue.get(block=false)
            except queue.Empty
                break
            else
                _new_output_char(char)
            end
        end
    end
end
