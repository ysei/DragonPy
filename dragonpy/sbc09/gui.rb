# coding: utf-8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require logging
require string
from dragonlib.utils.auto_shift import invert_shift

log = logging.getLogger(__name__)

begin
    # Python 3
    require queue
    require tkinter
    require tkinter
    require tkinter
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Queue as queue
    require Tkinter as tkinter
    require tkFileDialog as filedialog
    require tkMessageBox as messagebox
    require ScrolledText as scrolledtext
    require tkFont as TkFont
end

from dragonpy.core.gui import ScrolledTextGUI



class SBC09TkinterGUI < ScrolledTextGUI
    pass
end



