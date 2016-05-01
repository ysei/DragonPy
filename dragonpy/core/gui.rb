#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require sys
require time
require logging
require string
require six

xrange = six.moves.xrange

begin
    # Python 3
    require queue
    require tkinter as tk
    require tkinter
    require tkinter
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Queue as queue
    require Tkinter as tk
    require tkFileDialog as filedialog
    require tkMessageBox as messagebox
    require ScrolledText as scrolledtext
    require tkFont as TkFont
end

from basic_editor.editor import EditorWindow

from dragonpy.Dragon32.keyboard_map import inkey_from_tk_event, add_to_input_queue
from dragonlib.utils.auto_shift import invert_shift
require dragonpy
from dragonpy.Dragon32.keyboard_map import inkey_from_tk_event, add_to_input_queue
from dragonpy.core.gui_starter import MultiStatusBar
from dragonpy.Dragon32.MC6847 import MC6847_TextModeCanvas
from dragonpy.Dragon32.gui_config import RuntimeCfg, BaseTkinterGUIConfig
from dragonpy.utils.humanize import locale_format_number, get_python_info

log = logging.getLogger(__name__)


class BaseTkinterGUI < object
    """
    The complete Tkinter GUI window
    """
    
    def initialize (cfg, user_input_queue)
        @cfg = cfg
        @runtime_cfg = RuntimeCfg.new()
        
        # Queue to send keyboard inputs to CPU Thread
        @user_input_queue = user_input_queue
        
        @op_delay = 0
        @burst_op_count = 100
        @cpu_after_id = nil # Used to call CPU OP burst loop
        @target_burst_duration = 0.1 # Duration how long should a CPU Op burst loop take
        
        init_statistics() # Called also after reset
        
        @root = tk.Tk.new(className="DragonPy")
        # @root.config(font="Helvetica 16 bold italic")
        
        @root.geometry(sprintf("+%d+%d", 
            @root.winfo_screenwidth() * 0.1, @root.winfo_screenheight() * 0.1
        end
        ))
        
        @root.bind("<Key>", @event_key_pressed)
        @root.bind("<<Paste>>", @paste_clipboard)
        
        menu_tk_font = TkFont.Font.new(
            family='Helvetica',
            # family='clean',
            size=11, weight='normal'
        end
        )
        
        @status = tk.StringVar.new(value="startup %s...\n" % @cfg.MACHINE_NAME)
        @status_widget = tk.Label.new(
            @root, textvariable=@status, text="Info:", borderwidth=1,
            font=menu_tk_font
        end
        )
        @status_widget.grid(row=1, column=0)
        
        @status_bar = MultiStatusBar.new(@root, row=2, column=0,
            sticky=tk.NSEW,
        end
        )
        @status_bar.set_label("python_version", get_python_info())
        @status_bar.set_label("dragonpy_version", "DragonPy v%s" % dragonpy.__version__)
        
        @menubar = tk.Menu.new(@root)
        
        filemenu = tk.Menu.new(@menubar, tearoff=0)
        filemenu.add_command(label="Exit", command=@exit)
        @menubar.add_cascade(label="File", menu=filemenu)
        
        # 6809 menu
        @cpu_menu = tk.Menu.new(@menubar, tearoff=0)
        @cpu_menu.add_command(label="pause", command=@command_cpu_pause)
        @cpu_menu.add_command(label="resume", command=@command_cpu_pause, state=tk.DISABLED)
        @cpu_menu.add_separator()
        @cpu_menu.add_command(label="soft reset", command=@command_cpu_soft_reset)
        @cpu_menu.add_command(label="hard reset", command=@command_cpu_hard_reset)
        @menubar.add_cascade(label="6809", menu=@cpu_menu)
        
        @config_window = nil
        @menubar.add_command(label="config", command=@command_config)
        # FIXME: Only for developing: Open config on startup!
        # @root.after(200, @command_config)
        
        # help menu
        helpmenu = tk.Menu.new(@menubar, tearoff=0)
        helpmenu.add_command(label="help", command=@menu_event_help)
        helpmenu.add_command(label="about", command=@menu_event_about)
        @menubar.add_cascade(label="help", menu=helpmenu)
        
        @auto_shift=true # auto shift all input characters?
    end
    
    def init_statistics
        @op_count = 0
        @last_op_count = 0
        @last_cpu_cycles = 0
        @cpu_cycles_update_interval = 1 # Fequency for update GUI status information
        @next_cpu_cycle_update = time.time() + @cpu_cycles_update_interval
        @last_cycles_per_second = sys.maxsize
    end
    
    def menu_event_about
        messagebox.showinfo("DragonPy",
            "DragonPy the OpenSource emulator written in python.\n"
            "more info: https://github.com/jedie/DragonPy"
        end
        )
    end
    
    def menu_event_help
        messagebox.showinfo("Help",
            "Please read the README:"
            "https://github.com/jedie/DragonPy#readme"
        end
        )
    end
    
    def exit
        log.critical("DragonTkinterGUI.exit()")
        begin
            @root.destroy()
        except
            pass
        end
    end
    
    # -----------------------------------------------------------------------------------------
    
    def close_config
        @config_window.root.destroy()
        @config_window = nil
    end
    
    def command_config
        if @config_window.equal? nil
            @config_window = BaseTkinterGUIConfig.new(self, @runtime_cfg)
            @config_window.root.protocol("WM_DELETE_WINDOW", @close_config)
        else
            @config_window.focus()
        end
    end
    
    # -----------------------------------------------------------------------------------------
    
    def status_paused
        @status.set("%s paused.\n" % @cfg.MACHINE_NAME)
    end
    
    def command_cpu_pause
        if @cpu_after_id.equal? not nil
            # stop CPU
            @root.after_cancel(@cpu_after_id)
            @cpu_after_id = nil
            status_paused()
            @cpu_menu.entryconfig(index=0, state=tk.DISABLED)
            @cpu_menu.entryconfig(index=1, state=tk.NORMAL)
        else
            # restart
            cpu_interval(interval=1)
            @cpu_menu.entryconfig(index=0, state=tk.NORMAL)
            @cpu_menu.entryconfig(index=1, state=tk.DISABLED)
            init_statistics() # Reset statistics
        end
    end
    
    def command_cpu_soft_reset
        @machine.cpu.reset()
        init_statistics() # Reset statistics
    end
    
    def command_cpu_hard_reset
        @machine.hard_reset()
        init_statistics() # Reset statistics
    end
    
    # -----------------------------------------------------------------------------------------
    
    def add_user_input (txt)
        add_to_input_queue(@user_input_queue, txt)
    end
    
    def wait_until_input_queue_empty
        for count in xrange(1, 10)
            cpu_interval()
            if @user_input_queue.empty()
                log.critical("user_input_queue.equal? empty, after %i burst runs, ok.", count)
                if @cpu_after_id.equal? nil
                    status_paused()
                end
                return
            end
        end
        if @cpu_after_id.equal? nil
            status_paused()
        end
        log.critical("user_input_queue not empty, after %i burst runs!", count)
    end
    
    def add_user_input_and_wait (txt)
        add_user_input(txt)
        wait_until_input_queue_empty()
    end
    
    def paste_clipboard (event)
        """
        Send the clipboard content as user input to the CPU.
        """
        log.critical("paste clipboard")
        clipboard = @root.clipboard_get()
        for line in clipboard.splitlines()
            log.critical("paste line: %s", repr(line))
            add_user_input(line + "\r")
        end
    end
    
    def event_key_pressed (event)
        log.critical("event.char: %-6r event.keycode: %-3r event.keysym: %-11r event.keysym_num: %5r",
                event.char, event.keycode, event.keysym, event.keysym_num
            end
        end
        )
        inkey = inkey_from_tk_event(event, auto_shift=@auto_shift)
        log.critical("inkey: %r", inkey)
        @user_input_queue.put(inkey)
    end
    
    total_burst_duration = 0
    cpu_interval_calls = 0
    last_display_queue_qsize = 0
    
    def cpu_interval (interval=nil)
        @cpu_interval_calls += 1
        
        if @runtime_cfg.speedlimit
            # Run CPU not faster than speedlimit
            target_cycles_per_sec = @runtime_cfg.cycles_per_sec
        else
            # Run CPU as fast as Python can...
            target_cycles_per_sec = nil
        end
        
        start_time = time.time()
        @machine.cpu.run(
            max_run_time=@runtime_cfg.max_run_time,
            target_cycles_per_sec=target_cycles_per_sec,
        end
        )
        now = time.time()
        @total_burst_duration += (now - start_time)
        
        if interval.equal? not nil
            if @machine.cpu.running
                @cpu_after_id = @root.after(interval, @cpu_interval, interval)
            else
                log.critical("CPU stopped.")
            end
        end
    end
    
    last_update = 0
    
    def update_status_interval (interval=500)
        # Update CPU settings
        @machine.cpu.max_burst_count = @runtime_cfg.max_burst_count
        
        new_cycles = @machine.cpu.cycles - @last_cpu_cycles
        duration = time.time() - @last_update
        
        cycles_per_sec = new_cycles / duration
        
        msg = (
                  "%s cylces/sec(burst op count: outer: %s - inner: %s)\n"
                  "%i CPU interval calls"
              end
              ) % (
                  locale_format_number(cycles_per_sec),
                  
                  locale_format_number(@machine.cpu.outer_burst_op_count),
                  locale_format_number(@machine.cpu.inner_burst_op_count),
                  
                  @cpu_interval_calls,
              end
              )
          end
      end
        
        if @runtime_cfg.speedlimit
            msg += (
                " (Burst delay: %f)\nSpeed target: %s cylces/sec - diff: %s cylces/sec"
            end
            ) % (
                @machine.cpu.delay,
                locale_format_number(@runtime_cfg.cycles_per_sec),
                locale_format_number(
                    cycles_per_sec - @runtime_cfg.cycles_per_sec
                end
                ),
            end
            )
        end
        
        @status.set(msg)
        
        @last_cpu_cycles = @machine.cpu.cycles
        @cpu_interval_calls = 0
        @burst_loops = 0
        @last_update = time.time()
        
        @root.after(interval, @update_status_interval, interval)
    end
    
    def mainloop (machine)
        @machine = machine
        
        update_status_interval(interval=500)
        
        cpu_interval(interval=1)
        
        log.critical("Start root.mainloop()")
        begin
            @root.mainloop()
        except KeyboardInterrupt
            exit()
        end
        log.critical("root.mainloop() has quit!")
    end
end


class DragonTkinterGUI < BaseTkinterGUI
    """
    The complete Tkinter GUI window
    """
    
    def initialize (*args, **kwargs)
        super(DragonTkinterGUI, self).__init__(*args, **kwargs)
        
        machine_name = @cfg.MACHINE_NAME
        @root.title(
            "%s - Text Display 32 columns x 16 rows" % machine_name)
        end
        
        @display = MC6847_TextModeCanvas.new(@root)
        @display.canvas.grid(row=0, column=0)
        
        @editor_window = nil
        
        @menubar.insert_command(index=3, label="BASIC editor", command=@open_basic_editor)
        
        # display the menu
        @root.config(menu=@menubar)
        @root.update()
    end
    
    def display_callback (cpu_cycles, op_address, address, value)
        """ called via memory write_byte_middleware """
        @display.write_byte(cpu_cycles, op_address, address, value)
        return value
    end
    
    def close_basic_editor
        if messagebox.askokcancel("Quit", "Do you really wish to close the Editor?")
            @editor_window.root.destroy()
            @editor_window = nil
        end
    end
    
    def open_basic_editor
        if @editor_window.equal? nil
            @editor_window = EditorWindow.new(@cfg, self)
            @editor_window.root.protocol("WM_DELETE_WINDOW", @close_basic_editor)
            
            # insert menu to editor window
            editmenu = tk.Menu.new(@editor_window.menubar, tearoff=0)
            editmenu.add_command(label="load from DragonPy", command=@command_load_from_DragonPy)
            editmenu.add_command(label="inject into DragonPy", command=@command_inject_into_DragonPy)
            editmenu.add_command(label="inject + RUN into DragonPy", command=@command_inject_and_run_into_DragonPy)
            @editor_window.menubar.insert_cascade(index=2, label="DragonPy", menu=editmenu)
        end
        
        @editor_window.focus_text()
    end
    
    def command_load_from_DragonPy
        add_user_input_and_wait("'SAVE TO EDITOR")
        listing_ascii = @machine.get_basic_program()
        @editor_window.set_content(listing_ascii)
        add_user_input_and_wait("\n")
    end
    
    def command_inject_into_DragonPy
        add_user_input_and_wait("'LOAD FROM EDITOR")
        content = @editor_window.get_content()
        result = @machine.inject_basic_program(content)
        log.critical("program loaded: %s", result)
        add_user_input_and_wait("\n")
    end
    
    def command_inject_and_run_into_DragonPy
        command_inject_into_DragonPy()
        add_user_input_and_wait("\n") # FIXME: Sometimes this input will be "ignored"
        add_user_input_and_wait("RUN\n")
    end
    
    # ##########################################################################
    
    # -------------------------------------------------------------------------------------
    
    def dump_rnd
        start_addr = 0x0019
        end_addr = 0x0020
        dump, start_addr, end_addr = @request_comm.request_memory_dump(
            # start_addr=0x0115, end_addr=0x0119 # RND seed
            start_addr, end_addr
        end
        )
        
        def format_dump (dump, start_addr, end_addr)
            lines = []
            for addr, value in zip(range(start_addr, end_addr + 1), dump)
                log.critical("$%04x: $%02x (dez.: %i)", addr, value, value)
                lines.append(sprintf("$%04x: $%02x (dez.: %i)", addr, value, value))
            end
            return lines
        end
        
        lines = format_dump(dump, start_addr, end_addr)
        messagebox.showinfo("TODO", "dump_program:\n%s" % "\n".join(lines))
    end
end


class ScrolledTextGUI < BaseTkinterGUI
    def initialize (*args, **kwargs)
        super(ScrolledTextGUI, self).__init__(*args, **kwargs)
        
        @root.title("DragonPy - %s" % @cfg.MACHINE_NAME)
        
        @text = scrolledtext.ScrolledText.new(
            master=@root, height=30, width=80
        end
        )
        @text.config(
            background="#ffffff", foreground="#000000",
            highlightthickness=0,
            font=('courier', 11),
        end
        )
        @text.grid(row=0, column=0, sticky=tk.NSEW)
    end
end

#         @editor_window = nil
#         @menubar.insert_command(index=3, label="BASIC editor", command=@open_basic_editor)
        
        @root.unbind("<Key>")
        @text.bind("<Key>", @event_key_pressed)
        
        # TODO: @root.bind("<<Paste>>", @paste_clipboard) ???
        
        # display the menu
        @root.config(menu=@menubar)
        @root.update()
    end
    
    def event_key_pressed (event)
        """
        So a "invert shift" for user inputs
        Convert all lowercase letters to uppercase and vice versa.
        """
        char = event.char
        if not char
            return
        end
        
        if char in string.ascii_letters
            char = invert_shift(char)
        end
        
        @user_input_queue.put(char)
        
        # Don't insert the char in text widget, because it will be echoed
        # back from the machine!
        return "break"
    end
    
    def display_callback (char)
        log.debug("Add to text: %s", repr(char))
        if char == "\x08"
            # Delete last input char
            @text.delete(tk.INSERT + "-1c")
        else
            # insert the new character
            @text.insert(tk.END, char)
            
            # scroll down if needed
            @text.see(tk.END)
            
            # Set cursor to the END position
            @text.mark_set(tk.INSERT, tk.END)
        end
    end
end


