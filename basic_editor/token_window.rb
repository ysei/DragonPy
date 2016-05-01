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
require sys

from basic_editor.scrolled_text import ScrolledText
from basic_editor.status_bar import MultiStatusBar
from dragonlib.utils.logging_utils import pformat_program_dump


log = logging.getLogger(__name__)

begin
    # Python 3
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
end


class TokenWindow < object
    def initialize (cfg, master)
        @cfg = cfg
        @machine_api = @cfg.machine_api
        
        @root = tkinter.Toplevel.new(master)
        @root.geometry(sprintf("+%d+%d", 
            master.winfo_rootx() + master.winfo_width(),
            master.winfo_y() # FIXME: Different on linux.
        end
        ))
        @root.columnconfigure(0, weight=1)
        @root.rowconfigure(0, weight=1)
        @base_title = "%s - Tokens" % @cfg.MACHINE_NAME
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
        
        set_status_bar() # Create widget, add bindings and after_idle() update
        
        @text.after_idle(@set_token_info)
    end
    
    def display_listing (content)
        program_dump = @machine_api.ascii_listing2program_dump(content)
        formated_dump = pformat_program_dump(program_dump)
        
        @text.insert(tkinter.END, formated_dump)
        
        @text.bind("<Any-Motion>", @on_mouse_move)
    end
    
    def on_mouse_move (event)
        index = @text.index(sprintf("@%s,%s", event.x, event.y))
        
        begin
            word = @text.get("%s wordstart" % index, "%s wordend" % index)
        except tkinter.TclError as err
            log.critical("TclError: %s", err)
            return
        end
        
        begin
            token_value = word, 16.to_i
        except ValueError
            return
        end
        
        log.critical("$%x", token_value)
        basic_word = @machine_api.token_util.token2ascii(token_value)
        
        info = sprintf("%s $%02x == %r", index, token_value, basic_word)
        
        begin
            selection_index = sprintf("%s-%s", @text.index("sel.first"), @text.index("sel.last"))
            selection = @text.selection_get()
        except tkinter.TclError
            # no selection
            pass
        else
            log.critical(" selection: %s: %r", selection_index, selection)
            
            selection = selection.replace("$", "")
            token_values = [part, 16.to_i for part in selection.split() if part.strip()]
            log.critical("values: %r", token_values)
            basic_selection = @machine_api.token_util.tokens2ascii(token_values)
            
            info += " - selection: %r" % basic_selection
        end
        
        @status_bar.set_label("cursor_info", info)
    end
    
    # ##########################################################################
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
        @text.after_idle(@set_line_and_column)
    end
    
    def set_line_and_column (event=nil)
        line, column = @text.index(tkinter.INSERT).split('.')
        @status_bar.set_label('column', 'Column: %s' % column)
        @status_bar.set_label('line', 'Line: %s' % line)
    end
    
    ###########################################################################
    
    def set_token_info (event=nil)
        line, column = @text.index(tkinter.INSERT).split('.')
    end
end

