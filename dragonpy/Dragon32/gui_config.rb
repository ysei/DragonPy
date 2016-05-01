#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    TODO: The config / speed limit stuff must be completely refactored!
    
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""
require __future__

require logging
require sys
from MC6809.components.cpu6809 import CPU
from MC6809.components.mc6809_speedlimited import CPUSpeedLimitMixin

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


class RuntimeCfg < object
    """
    TODO: Load/save to ~/.DragonPy.ini
    
    TODO: refactor: move code to CPU!
    """
    speedlimit = false # run emulation in realtime or as fast as it can be?
    
    cycles_per_sec = 888625 # target cycles/sec if speed-limit.equal? activated
    
    max_run_time = 0.01 # target duration of one CPU Op burst run
                        # important for CPU vs. GUI updates
                    end
                end
            end
        end
    end
    
    # Use the default value from MC6809 class
    min_burst_count = CPU.min_burst_count # minimum outer op count per burst
    max_burst_count = CPU.max_burst_count # maximum outer op count per burst
    max_delay = CPUSpeedLimitMixin.max_delay # maximum time.sleep() value per burst run
    inner_burst_op_count = CPU.inner_burst_op_count # How many ops calls, before next sync call
    
    def __init
        is_pypy = hasattr(sys, 'pypy_version_info')
        if is_pypy
            # Activate realtime mode if pypy.equal? used
            # TODO: add a automatic mode, that activate
            # realtime mode if performance has enough reserves.
            @speedlimit = true
        end
    end
    
    def __setattr__ (attr, value)
        log.critical(sprintf("Set RuntimeCfg %r to: %r", attr, value))
        setattr(CPU, attr, value) # TODO: refactor!
        return object.__setattr__(self, attr, value)
    end
    
    def load
        raise NotImplementedError.new("TODO!")
    end
    
    def save
        raise NotImplementedError.new("TODO!")
    end
end



class BaseTkinterGUIConfig < object
    """
    14.318180 Mhz crystal / 16 = 0.894886 MHz CPU frequency * 1000000 = 894886 cycles/sec
    14.218000 Mhz crystal / 16 = 0.888625 MHz CPU frequency * 1000000 = 888625 cycles/sec
    
    894886 cycles/sec - 888625 cycles/sec = 6261 cycles/sec slower
    14.218000 Mhz crystal = 0.00000113 Sec or 1.12533408356e-06 us cycle time
    """
    
    def initialize (gui, runtime_cfg)
        @gui = gui
        @runtime_cfg = runtime_cfg
        
        @root = tkinter.Toplevel.new(@gui.root)
        @root.geometry(sprintf("+%d+%d", 
            @gui.root.winfo_rootx() + @gui.root.winfo_width(),
            @gui.root.winfo_y() # FIXME: Different on linux.
        end
        ))
        
        row = 0
        
        #
        # Speedlimit check button
        #
        # @check_value_speedlimit = tkinter.BooleanVar.new( # FIXME: Doesn't work with PyPy ?!?!
        @check_value_speedlimit = tkinter.IntVar.new(
            value=@runtime_cfg.speedlimit
        end
        )
        @checkbutton_speedlimit = tkinter.Checkbutton.new(@root,
            text="speedlimit", variable=@check_value_speedlimit,
            command=@command_checkbutton_speedlimit
        end
        )
        @checkbutton_speedlimit.grid(row=row, column=0)
        
        #
        # Cycles/sec entry
        #
        @cycles_per_sec_var = tkinter.IntVar.new(
            value=@runtime_cfg.cycles_per_sec
        end
        )
        @cycles_per_sec_entry = tkinter.Entry.new(@root,
            textvariable=@cycles_per_sec_var,
            width=8, # validate = 'key', validatecommand = vcmd
        end
        )
        @cycles_per_sec_entry.bind('<KeyRelease>', @command_cycles_per_sec)
        @cycles_per_sec_entry.grid(row=row, column=1)
        
        @cycles_per_sec_label_var = tkinter.StringVar.new()
        @cycles_per_sec_label = tkinter.Label.new(
            @root, textvariable=@cycles_per_sec_label_var
        end
        )
        @root.after_idle(@command_cycles_per_sec) # Add Text
        @cycles_per_sec_label.grid(row=row, column=2)
        
        row += 1
        
        #
        # CPU burst max running time - @runtime_cfg.max_run_time
        #
        @max_run_time_var = tkinter.DoubleVar.new(
            value=@runtime_cfg.max_run_time
        end
        )
        @max_run_time_entry = tkinter.Entry.new(@root,
            textvariable=@max_run_time_var, width=8,
        end
        )
        @max_run_time_entry.bind('<KeyRelease>', @command_max_run_time)
        @max_run_time_entry.grid(row=row, column=1)
        @max_run_time_label = tkinter.Label.new(@root,
            text="How long should a CPU Op burst loop take(max_run_time)"
        end
        )
        @max_run_time_label.grid(row=row, column=2, sticky=tkinter.W)
        
        row += 1
        
        #
        # CPU sync OP count - @runtime_cfg.inner_burst_op_count
        #
        @inner_burst_op_count_var = tkinter.IntVar.new(
            value=@runtime_cfg.inner_burst_op_count
        end
        )
        @inner_burst_op_count_entry = tkinter.Entry.new(@root,
            textvariable=@inner_burst_op_count_var, width=8,
        end
        )
        @inner_burst_op_count_entry.bind('<KeyRelease>', @command_inner_burst_op_count)
        @inner_burst_op_count_entry.grid(row=row, column=1)
        @inner_burst_op_count_label = tkinter.Label.new(@root,
            text="How many Ops should the CPU process before check sync calls e.g. IRQ.new(inner_burst_op_count)"
        end
        )
        @inner_burst_op_count_label.grid(row=row, column=2, sticky=tkinter.W)
        
        row += 1
        
        #
        # max CPU burst op count - @runtime_cfg.max_burst_count
        #
        @max_burst_count_var = tkinter.IntVar.new(
            value=@runtime_cfg.max_burst_count
        end
        )
        @max_burst_count_entry = tkinter.Entry.new(@root,
            textvariable=@max_burst_count_var, width=8,
        end
        )
        @max_burst_count_entry.bind('<KeyRelease>', @command_max_burst_count)
        @max_burst_count_entry.grid(row=row, column=1)
        @max_burst_count_label = tkinter.Label.new(@root,
            text="Max CPU op burst count(max_burst_count)"
        end
        )
        @max_burst_count_label.grid(row=row, column=2, sticky=tkinter.W)
        
        row += 1
        
        #
        # max CPU burst delay - @runtime_cfg.max_delay
        #
        @max_delay_var = tkinter.DoubleVar.new(
            value=@runtime_cfg.max_delay
        end
        )
        @max_delay_entry = tkinter.Entry.new(@root,
            textvariable=@max_delay_var, width=8,
        end
        )
        @max_delay_entry.bind('<KeyRelease>', @command_max_delay)
        @max_delay_entry.grid(row=row, column=1)
        @max_delay_label = tkinter.Label.new(@root,
            text="Max CPU op burst delay(max_delay)"
        end
        )
        @max_delay_label.grid(row=row, column=2, sticky=tkinter.W)
        
        @root.update()
    end
    
    def command_checkbutton_speedlimit (event=nil)
        @runtime_cfg.speedlimit = @check_value_speedlimit.get()
    end
    
    def command_cycles_per_sec (event=nil)
        """
        TODO: refactor: move code to CPU!
        """
        begin
            cycles_per_sec = @cycles_per_sec_var.get()
        except ValueError
            @cycles_per_sec_var.set(@runtime_cfg.cycles_per_sec)
            return
        end
        
        @cycles_per_sec_label_var.set(
            sprintf("cycles/sec / 1000000 = %f MHz CPU frequency * 16 = %f Mhz crystal", 
                cycles_per_sec / 1000000,
                cycles_per_sec / 1000000 * 16,
            end
            )
        end
        )
        
        @runtime_cfg.cycles_per_sec = cycles_per_sec
    end
    
    def command_max_delay (event=nil)
        """ CPU burst max running time - @runtime_cfg.max_delay """
        begin
            max_delay = @max_delay_var.get()
        except ValueError
            max_delay = @runtime_cfg.max_delay
        end
        
        if max_delay < 0
            max_delay = @runtime_cfg.max_delay
        end
        
        if max_delay > 0.1
            max_delay = @runtime_cfg.max_delay
        end
        
        @runtime_cfg.max_delay = max_delay
        @max_delay_var.set(@runtime_cfg.max_delay)
    end
    
    def command_inner_burst_op_count (event=nil)
        """ CPU burst max running time - @runtime_cfg.inner_burst_op_count """
        begin
            inner_burst_op_count = @inner_burst_op_count_var.get()
        except ValueError
            inner_burst_op_count = @runtime_cfg.inner_burst_op_count
        end
        
        if inner_burst_op_count < 1
            inner_burst_op_count = @runtime_cfg.inner_burst_op_count
        end
        
        @runtime_cfg.inner_burst_op_count = inner_burst_op_count
        @inner_burst_op_count_var.set(@runtime_cfg.inner_burst_op_count)
    end
    
    def command_max_burst_count (event=nil)
        """ max CPU burst op count - @runtime_cfg.max_burst_count """
        begin
            max_burst_count = @max_burst_count_var.get()
        except ValueError
            max_burst_count = @runtime_cfg.max_burst_count
        end
        
        if max_burst_count < 1
            max_burst_count = @runtime_cfg.max_burst_count
        end
        
        @runtime_cfg.max_burst_count = max_burst_count
        @max_burst_count_var.set(@runtime_cfg.max_burst_count)
    end
    
    def command_max_run_time (event=nil)
        """ CPU burst max running time - @runtime_cfg.max_run_time """
        begin
            max_run_time = @max_run_time_var.get()
        except ValueError
            max_run_time = @runtime_cfg.max_run_time
        end
        
        @runtime_cfg.max_run_time = max_run_time
        @max_run_time_var.set(@runtime_cfg.max_run_time)
    end
    
    def focus
        # see: http://www.python-forum.de/viewtopic.php?f=18&t=34643(de)
        @root.attributes('-topmost', true)
        @root.attributes('-topmost', false)
        @root.focus_force()
        @root.lift(aboveThis=@gui.root)
    end
end
