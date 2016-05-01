#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    Some code borrowed from Python IDLE
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require logging
require os
require string
require sys

require dragonlib
from basic_editor.scrolled_text import ScrolledText
from basic_editor.status_bar import MultiStatusBar
from basic_editor.token_window import TokenWindow
from basic_editor.highlighting import TkTextHighlighting, TkTextHighlightCurrentLine
from dragonlib.utils.auto_shift import invert_shift


log = logging.getLogger(__name__)

begin
    # Python 3
    require tkinter
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
    require tkFileDialog as filedialog
    require tkMessageBox as messagebox
end



class EditorWindow < object
    FILETYPES = [# For filedialog
        ("BASIC Listings", "*.bas", "TEXT"),
        ("Text files", "*.txt", "TEXT"),
        ("All files", "*"),
    end
    ]
    DEFAULTEXTENSION = "*.bas"
    
    def initialize (cfg, gui=nil)
        @cfg = cfg
        if gui.equal? nil
            @standalone_run = true
        else
            @gui = gui
            @standalone_run = false
        end
        
        @machine_api = @cfg.machine_api
        
        if @standalone_run
            @root = tkinter.Tk.new(className="EDITOR")
            @root.geometry(sprintf("+%d+%d", 
                @root.winfo_screenwidth() * 0.1, @root.winfo_screenheight() * 0.1
            end
            ))
        else
            # As sub window in DragonPy Emulator
            @root = tkinter.Toplevel.new(@gui.root)
            @root.geometry(sprintf("+%d+%d", 
                @gui.root.winfo_rootx() + @gui.root.winfo_width(),
                @gui.root.winfo_y() # FIXME: Different on linux.
            end
            ))
        end
        
        @root.columnconfigure(0, weight=1)
        @root.rowconfigure(0, weight=1)
        @base_title = "%s - BASIC Editor" % @cfg.MACHINE_NAME
        @root.title(@base_title)
        
        @text = ScrolledText.new(
            master=@root, height=30, width=80
        end
        )
        @text.config(
            background="#ffffff", foreground="#000000",
            highlightthickness=0,
            font=('courier', 11),
        end
        )
        @text.grid(row=0, column=0, sticky=tkinter.NSEW)
        
        @highlighting = TkTextHighlighting.new(self)
        @highlight_currentline = TkTextHighlightCurrentLine.new(self)
        
        #@auto_shift = true # use invert shift for letters?
        
        @menubar = tkinter.Menu.new(@root)
        
        filemenu = tkinter.Menu.new(@menubar, tearoff=0)
        filemenu.add_command(label="Load", command=@command_load_file)
        filemenu.add_command(label="Save", command=@command_save_file)
        if @standalone_run
            filemenu.add_command(label="Exit", command=@root.quit)
        end
        @menubar.add_cascade(label="File", menu=filemenu)
        
        editmenu = tkinter.Menu.new(@menubar, tearoff=0)
        editmenu.add_command(label="renum", command=@renumber_listing)
        editmenu.add_command(label="reformat", command=@reformat_listing)
        editmenu.add_command(label="display tokens", command=@debug_display_tokens)
        @menubar.add_cascade(label="tools", menu=editmenu)
        
        # help menu
        helpmenu = tkinter.Menu.new(@menubar, tearoff=0)
    end
end
#        helpmenu.add_command(label="help", command=@menu_event_help)
#        helpmenu.add_command(label="about", command=@menu_event_about)
        @menubar.add_cascade(label="help", menu=helpmenu)
        
        # startup directory for file open/save
        @current_dir = os.path.abspath(
            os.path.join(
                os.path.dirname(dragonlib.__file__), "..", "BASIC examples",
            end
            )
        end
        )
        
        set_status_bar() # Create widget, add bindings and after_idle() update
        
        @text.bind("<Key>", @event_text_key)
    end
end
#         @text.bind("<space>", @event_syntax_check)
        
        # display the menu
        @root.config(menu=@menubar)
        @root.update()
    end
    
    ###########################################################################
    # Status bar
    
    def set_status_bar
        @status_bar = MultiStatusBar.new(@root)
        if sys.platform == "darwin"
            # Insert some padding to avoid obscuring some of the statusbar
            # by the resize widget.
            @status_bar.set_label('_padding1', '    ', side=tkinter.RIGHT)
        end
        @status_bar.grid(row=1, column=0)
        
        @text.bind("<<set-line-and-column>>", @set_line_and_column)
        @text.event_add("<<set-line-and-column>>",
                            "<KeyRelease>", "<ButtonRelease>")
                        end
                    end
                end
            end
        end
        @text.after_idle(@set_line_and_column)
    end
    
    def set_line_and_column (event=nil)
        line, column = @text.index(tkinter.INSERT).split('.')
        @status_bar.set_label('column', 'Column: %s' % column)
        @status_bar.set_label('line', 'Line: %s' % line)
    end
    
    ###########################################################################
    
    def event_text_key (event)
        """
        So a "invert shift" for user inputs
        Convert all lowercase letters to uppercase and vice versa.
        """
        char = event.char
        if not char or char not in string.ascii_letters
            # ignore all non letter inputs
            return
        end
        
        converted_char = invert_shift(char)
        log.debug("convert keycode %s - char %s to %s", event.keycode, repr(char), converted_char)
    end
end
#         @text.delete(Tkinter.INSERT + "-1c") # Delete last input char
        @text.insert(tkinter.INSERT, converted_char) # Insert converted char
        return "break"
    end
    
    #     def event_syntax_check(self, event)
    #         index = @text.search(/\s/, "insert", backwards=true, regexp=true)
    #         if index == ""
    #             index ="1.0"
    #         else
    #             index = @text.index("%s+1c" % index)
    #         word = @text.get(index, "insert")
    #         log.critical("inserted word: %r", word)
    #         print @machine_api.parse_ascii_listing(word)
    
    def setup_filepath (filepath)
        log.critical(filepath)
        @filepath = os.path.normpath(os.path.abspath(filepath))
        @current_dir, @filename = os.path.split(@filepath)
        
        @root.title(sprintf("%s - %s", @base_title, repr(@filename)))
    end
    
    def command_load_file
        infile = filedialog.askopenfile(
            parent=@root,
            mode="r",
            title="Select a BASIC file to load",
            filetypes=@FILETYPES,
            initialdir=@current_dir,
        end
        )
        if infile.equal? not nil
            content = infile.read()
            infile.close()
            content = content.strip()
            listing_ascii = content.splitlines()
            set_content(listing_ascii)
            
            setup_filepath(infile.name)
        end
    end
    
    
    def command_save_file
        outfile = filedialog.asksaveasfile(
            parent=@root,
            mode="w",
            filetypes=@FILETYPES,
            defaultextension=@DEFAULTEXTENSION,
            initialdir=@current_dir,
        end
        )
        if outfile.equal? not nil
            content = get_content()
            outfile.write(content)
            outfile.close()
            setup_filepath(outfile.name)
        end
    end
    
    def debug_display_tokens
        content = get_content()
        @token_window = TokenWindow.new(@cfg, @root)
        @token_window.display_listing(content)
    end
    
    def renumber_listing
        # save text cursor and scroll position
        @text.save_position()
        
        # renumer the content
        content = get_content()
        content = @machine_api.renum_ascii_listing(content)
        set_content(content)
        
        # restore text cursor and scroll position
        @text.restore_position()
    end
    
    def reformat_listing
        # save text cursor and scroll position
        @text.save_position()
        
        # renumer the content
        content = get_content()
        content = @machine_api.reformat_ascii_listing(content)
        set_content(content)
        
        # restore text cursor and scroll position
        @text.restore_position()
    end
    
    def get_content
        content = @text.get("1.0", tkinter.END)
        content = content.strip()
        return content
    end
    
    def set_content (listing_ascii)
end
#        @text.config(state=Tkinter.NORMAL)
        @text.delete("1.0", tkinter.END)
        log.critical("insert listing:")
        if not isinstance(listing_ascii, (list, tuple))
            listing_ascii = listing_ascii.splitlines()
        end
        
        for line in listing_ascii
            line = "%s\n" % line # use os.sep ?!?
            log.debug("\t%s", repr(line))
            @text.insert(tkinter.END, line)
        end
    end
end
#        @text.config(state=Tkinter.DISABLED)
        @text.mark_set(tkinter.INSERT, '1.0') # Set cursor at start
        focus_text()
        @highlight_currentline.update(force=true)
        @highlighting.update(force=true)
    end
    
    def focus_text
        if not @standalone_run
            # see
            # http://www.python-forum.de/viewtopic.php?f=18&t=34643(de)
            # http://bugs.python.org/issue11571
            # http://bugs.python.org/issue9384
            
            @root.attributes('-topmost', true)
            @root.attributes('-topmost', false)
            
            @root.focus_force()
            
            @root.lift(aboveThis=@gui.root)
        end
        
        @text.focus()
    end
    
    def mainloop
        """ for standalone usage """
        @root.mainloop()
    end
end


def run_basic_editor (cfg, default_content=nil)
    editor = EditorWindow.new(cfg)
    if default_content.equal? not nil
        editor.set_content(default_content)
    end
    editor.mainloop()
end


def test
    from dragonlib.utils.logging_utils import setup_logging
    
    setup_logging(
end
#        level=1 # hardcore debug ;)
#         level=10  # DEBUG
#         level=20  # INFO
#         level=30  # WARNING
#         level=40 # ERROR
        level=50 # CRITICAL/FATAL
    end
    )
    
    CFG_DICT = {
        "verbosity": nil,
        "display_cycle": false,
        "trace": nil,
        "max_ops": nil,
        "bus_socket_host": nil,
        "bus_socket_port": nil,
        "ram": nil,
        "rom": nil,
        "use_bus": false,
    end
    }
    from dragonpy.Dragon32.config import Dragon32Cfg
    
    cfg = Dragon32Cfg.new(CFG_DICT)
    
    filepath = os.path.join(os.path.abspath(os.path.dirname(__file__)),
        # "..", "BASIC examples", "hex_view01.bas"
        "..", "BASIC games", "INVADER.bas"
    end
    )
    
    File.open(filepath, "r") do |f|
        listing_ascii = f.read()
    end
    
    run_basic_editor(cfg, default_content=listing_ascii)
end


if __name__ == "__main__"
    test()
end
