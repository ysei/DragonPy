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


log = logging.getLogger(__name__)

begin
    # Python 3
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
end


class MultiStatusBar(tkinter.Frame)
    """
    code from idlelib.MultiStatusBar.MultiStatusBar
    """
    
    def initialize (master, **kw)
        tkinter.Frame.__init__(self, master, **kw)
        @labels = {}
    end
    
    def set_label (name, text='', side=tkinter.LEFT)
        if name not in @labels
            label = tkinter.Label.new(self, bd=1, relief=tkinter.SUNKEN, anchor=tkinter.W)
            label.pack(side=side)
            @labels[name] = label
        else
            label = @labels[name]
        end
        label.config(text=text)
    end
end
