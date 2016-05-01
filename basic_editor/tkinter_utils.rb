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


class TkTextTag < object
    _id=0
    def initialize (text_widget, **config)
        @id = @id
        @id+=1
        text_widget.tag_configure(@id, config)
    end
end
