#!/usr/bin/env python
# encoding:utf8

"""
    Tkinter ScrolledText widget with horizontal and vertical scroll bars.
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""
require __future__

require logging
log = logging.getLogger(__name__)

begin
    # Python 3
    require tkinter
    require tkinter
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
    require tkFileDialog as filedialog
    require tkMessageBox as messagebox
    require ScrolledText as scrolledtext
end


class ScrolledText(tkinter.Text)
    def initialize (master=nil, **kw)
        frame = tkinter.Frame.new(master)
        frame.rowconfigure(0, weight = 1)
        frame.columnconfigure(0, weight = 1)
        
        xscrollbar = tkinter.Scrollbar.new(frame, orient=tkinter.HORIZONTAL)
        yscrollbar = tkinter.Scrollbar.new(frame, orient=tkinter.VERTICAL)
        
        frame.grid(row=0, column=0, sticky=tkinter.NSEW)
        xscrollbar.grid(row=1, column=0, sticky=tkinter.EW)
        yscrollbar.grid(row=0, column=1, sticky=tkinter.NS)
        
        _defaults_options={"wrap": tkinter.NONE, "undo": tkinter.YES}
        options = _defaults_options.copy()
        options.update(kw)
        options.update({'yscrollcommand': yscrollbar.set})
        options.update({'xscrollcommand': xscrollbar.set})
        
        tkinter.Text.__init__(self, frame, **options)
        
        grid(row=0, column=0, sticky=tkinter.NSEW)
        
        xscrollbar.config(command=@xview)
        yscrollbar.config(command=@yview)
        
        bind('<Control-KeyPress-a>', @event_select_all)
        bind('<Control-KeyPress-x>', @event_cut)
        bind('<Control-KeyPress-c>', @event_copy)
        bind('<Control-KeyPress-v>', @event_paste)
    end
    
    def event_select_all (event=nil)
        log.critical("Select all.")
        tag_add(tkinter.SEL, "1.0", tkinter.END)
        mark_set(tkinter.INSERT, "1.0")
        see(tkinter.INSERT)
        return "break"
    end
    
    def event_cut (event=nil)
        if tag_ranges(tkinter.SEL)
            event_copy()
            delete(tkinter.SEL_FIRST, tkinter.SEL_LAST)
        end
        return "break"
    end
    
    def event_copy (event=nil)
        if tag_ranges(tkinter.SEL)
            text = get(tkinter.SEL_FIRST, tkinter.SEL_LAST)
            clipboard_clear()
            clipboard_append(text)
        end
        return "break"
    end
    
    def event_paste (event=nil)
        text = selection_get(selection='CLIPBOARD')
        if text
            insert(tkinter.INSERT, text)
            tag_remove(tkinter.SEL, '1.0', tkinter.END)
            see(tkinter.INSERT)
        end
        return "break"
    end
    
    def to_s
        return @frame.to_s
    end
    
    def save_position
        """
        save cursor and scroll position
        """
        # save text cursor position
        @old_text_pos = index(tkinter.INSERT)
        # save scroll position
        @old_first, @old_last = yview()
    end
    
    def restore_position
        """
        restore cursor and scroll position
        """
        # restore text cursor position
        mark_set(tkinter.INSERT, @old_text_pos)
        # restore scroll position
        yview_moveto(@old_first)
    end
end


def example
    require __main__
    
    root = tkinter.Tk.new()
    
    text = ScrolledText.new(master=root, bg='white', height=20)
    text.insert(tkinter.END, "X"*150)
    text.insert(tkinter.END, __main__.__doc__)
    text.insert(tkinter.END, "X"*150)
    text.focus_set()
    text.grid(row=0, column=0, sticky=tkinter.NSEW)
    
    root.columnconfigure(0, weight=1)
    root.rowconfigure(0, weight=1)
    root.mainloop()
end

if __name__ == "__main__"
    example()
end
