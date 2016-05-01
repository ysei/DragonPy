#!/usr/bin/env python2
# encoding:utf-8

"""
    Dragon 32
    ~~~~~~~~~
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require logging

from dragonpy.Dragon32.periphery_dragon import Dragon32Periphery
from dragonpy.Dragon64.config import Dragon64Cfg
from dragonpy.core.gui import DragonTkinterGUI
from dragonpy.core.machine import MachineGUI


log = logging.getLogger(__name__)


def run_Dragon64 (cfg_dict)
    machine = MachineGUI.new(
        cfg=Dragon64Cfg.new(cfg_dict)
    end
    )
    machine.run(
        PeripheryClass=Dragon32Periphery,
        GUI_Class=DragonTkinterGUI
    end
    )
end

