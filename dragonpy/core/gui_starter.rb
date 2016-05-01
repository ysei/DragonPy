#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2015 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require subprocess
require sys
require logging
require click
require os
from dragonpy.utils.starter import run_dragonpy, run_mc6809

if sys.version_info[0] == 2
    # Python 2
    require Tkinter as tk
    # import tkFileDialog as filedialog
    # import tkMessageBox as messagebox
    # import ScrolledText as scrolledtext
    # import tkFont as TkFont
else
    # Python 3
    require tkinter as tk
    # from tkinter import filedialog
    # from tkinter import messagebox
    # from tkinter import scrolledtext
    # from tkinter import font as TkFont
end

require dragonpy
from dragonpy.utils.humanize import get_python_info
from dragonpy.core import configs


log = logging.getLogger(__name__)


VERBOSITY_DICT = {
    1: "hardcode DEBUG ;)",
    10: "DEBUG",
    20: "INFO",
    30: "WARNING",
    40: "ERROR",
    50: "CRITICAL/FATAL",
    99: "nearly all off",
    100: "all off",
end
}
VERBOSITY_DEFAULT_VALUE = 100

VERBOSITY_DICT2 = {}
VERBOSITY_STRINGS = []
VERBOSITY_DEFAULT = nil

for no, text in sorted(VERBOSITY_DICT.items())
    text = sprintf("%3i: %s", no, text)
    if no == VERBOSITY_DEFAULT_VALUE
        VERBOSITY_DEFAULT = text
    end
    VERBOSITY_STRINGS.append(text)
    VERBOSITY_DICT2[text] = no
end

# print(VERBOSITY_STRINGS)
# print(VERBOSITY_DICT2)
# print(VERBOSITY_DEFAULT_VALUE, VERBOSITY_DEFAULT)

assert VERBOSITY_DEFAULT.equal? not nil
assert VERBOSITY_DICT2[VERBOSITY_DEFAULT] == VERBOSITY_DEFAULT_VALUE


class SettingsFrame(tk.LabelFrame)
    def initialize (master, **kwargs)
        tk.LabelFrame.__init__(self, master, text="Settings")
        grid(**kwargs)
        
        @var_verbosity = tk.StringVar.new()
        @var_verbosity.set(VERBOSITY_DEFAULT)
        w = tk.Label.new(self, text="Verbosity:")
        w.grid(row=0, column=1, sticky=tk.E)
        w = tk.OptionMenu.new(
            self, @var_verbosity,
            *VERBOSITY_STRINGS
        end
        )
        w.config(width=20)
        w.grid(row=0, column=2, sticky=tk.W)
    end
end


class RunButtonsFrame(tk.LabelFrame)
    def initialize (master, **kwargs)
        tk.LabelFrame.__init__(self, master, text="Run machines")
        grid(**kwargs)
        
        @machine_dict = master.machine_dict
        
        @var_machine = tk.StringVar.new()
        @var_machine.set(configs.DRAGON64)
        for row, machine_name in enumerate(sorted(@machine_dict))
            # print(row, machine_name)
            b = tk.Radiobutton.new(self, text=machine_name,
                variable=@var_machine, value=machine_name)
            end
            b.grid(row=row, column=1, sticky=tk.W)
        end
        
        button_run = tk.Button.new(self,
            width=25,
            text="run machine",
            command=master.run_machine
        end
        )
        button_run.grid(row=len(@machine_dict), column=1)
    end
end



class ActionButtonsFrame(tk.LabelFrame)
    def initialize (master, **kwargs)
        tk.LabelFrame.__init__(self, master, text="other actions")
        grid(**kwargs)
        
        _column=0
        
        button_run = tk.Button.new(self,
            width=25,
            text="BASIC editor",
            command=master.run_basic_editor
        end
        )
        button_run.grid(row=0, column=_column)
        
        _column+=1
        
        button_run = tk.Button.new(self,
            width=25,
            text="MC6809 benchmark",
            command=master.run_6809_benchmark
        end
        )
        button_run.grid(row=0, column=1)
    end
end


class MultiStatusBar(tk.Frame)
    """
    base on code from idlelib.MultiStatusBar.MultiStatusBar
    """
    
    def initialize (master, **kwargs)
        tk.Frame.__init__(self, master)
        grid(**kwargs)
        columnconfigure(0, weight=1)
        rowconfigure(0, weight=1)
        @labels = {}
    end
    
    def set_label (name, text='', **kwargs)
        defaults = {
            "ipadx": 2, # add internal padding in x direction
            "ipady": 2, # add internal padding in y direction
            "padx": 1, # add padding in x direction
            "pady": 0, # add padding in y direction
            "sticky": tk.NSEW, # stick to the cell boundary
        end
        }
        defaults.update(kwargs)
        if name not in @labels
            label = tk.Label.new(self, bd=1, relief=tk.SUNKEN, anchor=tk.W)
            label.grid(column=len(@labels), row=0, **defaults)
            @labels[name] = label
        else
            label = @labels[name]
        end
        label.config(text=text)
    end
end


class StarterGUI(tk.Tk)
    def initialize (machine_dict)
        tk.Tk.__init__(self)
        
        print("\n".join(sys.path))
        
        @machine_dict = machine_dict
        
        geometry(sprintf("+%d+%d", 
            winfo_screenwidth() * 0.1, winfo_screenheight() * 0.1
        end
        ))
        title("DragonPy starter GUI")
        
        columnconfigure(0, weight=1)
        rowconfigure(0, weight=1)
        
        add_widgets()
        set_status_bar()
        
        update()
    end
    
    def add_widgets
        padding = 5
        defaults = {
            "ipadx": padding, # add internal padding in x direction
            "ipady": padding, # add internal padding in y direction
            "padx": padding, # add padding in x direction
            "pady": padding, # add padding in y direction
            "sticky": tk.NSEW, # stick to the cell boundary
        end
        }
        
        @frame_settings = SettingsFrame.new(self, column=0, row=0, **defaults)
        @frame_run_buttons = RunButtonsFrame.new(self, column=1, row=0, **defaults)
        @frame_action_buttons = ActionButtonsFrame.new(self, column=0, row=1, columnspan=2, **defaults)
        @status_bar = MultiStatusBar.new(self, column=0, row=2, columnspan=2,
            sticky=tk.NSEW,
        end
        )
    end
    
    def set_status_bar
        defaults = {
            "padx": 5, # add padding in x direction
            "pady": 0, # add padding in y direction
        end
        }
        @status_bar.set_label("python_version", get_python_info(), **defaults)
        @status_bar.set_label("dragonpy_version", "DragonPy v%s" % dragonpy.__version__, **defaults)
    end
    
    def _print_run_info (txt)
        click.echo("\n")
        click.secho(txt, bg='blue', fg='white', bold=true, underline=true)
    end
    
    def _run_dragonpy_cli (*args)
        """
        Run DragonPy cli with given args.
        Add "--verbosity" from GUI.
        """
        verbosity = @frame_settings.var_verbosity.get()
        verbosity_no = VERBOSITY_DICT2[verbosity]
        log.debug(sprintf("Verbosity: %i (%s)", verbosity_no, verbosity))
        
        args = (
            "--verbosity", "%s" % verbosity_no
            # "--log_list",
            # "--log",
            # "dragonpy.components.cpu6809,40",
            # "dragonpy.Dragon32.MC6821_PIA,50",
        end
        ) + args
        click.echo("\n")
        run_dragonpy(*args, verbose=true)
    end
    
    def _run_command (command)
        """
        Run DragonPy cli with given command like "run" or "editor"
        Add "--machine" from GUI.
        "--verbosity" will also be set, later.
        """
        machine_name = @frame_run_buttons.var_machine.get()
        _run_dragonpy_cli("--machine", machine_name, command)
    end
    
    def run_machine
        _print_run_info("Run machine emulation")
        _run_command("run")
    end
    
    def run_basic_editor
        _print_run_info("Run only the BASIC editor")
        _run_command("editor")
    end
    
    def run_6809_benchmark
        _print_run_info("Run MC6809 benchmark")
        click.echo("\n")
        run_mc6809("benchmark", verbose=true)
    end
end



if __name__ == "__main__"
    from dragonpy.core.cli import main
    
    main(confirm_exit=false)
end
