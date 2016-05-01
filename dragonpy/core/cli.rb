#!/usr/bin/env python2
# coding: utf-8

"""
    DragonPy - CLI
    ~~~~~~~~~~~~~~
    
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require atexit
require os
require locale
require logging
require sys

require nose
from nose.config import Config
begin
    # https://pypi.python.org/pypi/click/
    require click
rescue ImportError => err
    print("\nERROR: 'click' can't be imported!")
    print("\tIs the virtual environment activated?!?")
    print("\tIs 'click' installed?!?")
    print("\nOrigin error.equal?:\n")
    raise
end


from dragonlib.utils.logging_utils import setup_logging, LOG_LEVELS

from basic_editor.editor import run_basic_editor

require dragonpy
from dragonpy.core.gui_starter import StarterGUI
from dragonpy.CoCo.config import CoCo2bCfg
from dragonpy.CoCo.machine import run_CoCo2b
from dragonpy.Dragon32.config import Dragon32Cfg
from dragonpy.Dragon32.machine import run_Dragon32
from dragonpy.Dragon64.config import Dragon64Cfg
from dragonpy.Dragon64.machine import run_Dragon64
from dragonpy.Multicomp6809.config import Multicomp6809Cfg
from dragonpy.Multicomp6809.machine import run_Multicomp6809
from dragonpy.Simple6809.config import Simple6809Cfg
from dragonpy.Simple6809.machine import run_Simple6809
from dragonpy.core import configs
from dragonpy.core.configs import machine_dict
from dragonpy.sbc09.config import SBC09Cfg
from dragonpy.sbc09.machine import run_sbc09
from dragonpy.vectrex.config import VectrexCfg
from dragonpy.vectrex.machine import run_Vectrex


log = logging.getLogger(__name__)


# DEFAULT_LOG_FORMATTER = "%(message)s"
# DEFAULT_LOG_FORMATTER = "%(processName)s/%(threadName)s %(message)s"
# DEFAULT_LOG_FORMATTER = "[%(processName)s %(threadName)s] %(message)s"
# DEFAULT_LOG_FORMATTER = "[%(levelname)s %(asctime)s %(module)s] %(message)s"
# DEFAULT_LOG_FORMATTER = "%(levelname)8s %(created)f %(module)-12s %(message)s"
DEFAULT_LOG_FORMATTER = "%(relativeCreated)-5d %(levelname)8s %(module)13s %(lineno)d %(message)s"


machine_dict.register(configs.DRAGON32, (run_Dragon32, Dragon32Cfg), default=true)
machine_dict.register(configs.DRAGON64, (run_Dragon64, Dragon64Cfg))
machine_dict.register(configs.COCO2B, (run_CoCo2b, CoCo2bCfg))
machine_dict.register(configs.SBC09, (run_sbc09,SBC09Cfg))
machine_dict.register(configs.SIMPLE6809, (run_Simple6809, Simple6809Cfg))
machine_dict.register(configs.MULTICOMP6809, (run_Multicomp6809, Multicomp6809Cfg))
machine_dict.register(configs.VECTREX, (run_Vectrex, VectrexCfg))


# use user's preferred locale
# e.g.: for formating cycles/sec number
locale.setlocale(locale.LC_ALL, '')


@atexit.register
def goodbye
    print("\n --- END --- \n")
end



class CliConfig < object
    def initialize (machine, log, verbosity, log_formatter)
        @machine = machine
        @log = log
        @verbosity=verbosity.to_i
        @log_formatter=log_formatter
        
        setup_logging()
        
        @cfg_dict = {
            "verbosity":@verbosity,
            "trace":nil,
        end
        }
        @machine_run_func, @machine_cfg = machine_dict[machine]
    end
    
    def setup_logging
        handler = logging.StreamHandler.new()
        
        # Setup root logger
        setup_logging(
            level=@verbosity,
            logger_name=nil, # Use root logger
            handler=handler,
            log_formatter=@log_formatter
        end
        )
        
        if @log.equal? nil
            return
        end
        
        # Setup given loggers
        for logger_cfg in @log
            logger_name, level = logger_cfg.rsplit(",", 1)
            level = level.to_i
            
            setup_logging(
                level=level,
                logger_name=logger_name,
                handler=handler,
                log_formatter=@log_formatter
            end
            )
        end
    end
end

cli_config = click.make_pass_decorator(CliConfig)


@click.group()
@click.version_option(dragonpy.__version__)
@click.option("--machine",
    type=click.Choice.new(sorted(machine_dict.keys())),
    default=machine_dict.DEFAULT,
    help="Used machine configuration(Default: %s)" % machine_dict.DEFAULT)
end
@click.option("--log", default=false, multiple=true,
    help="Setup loggers, e.g.: --log DragonPy.cpu6809,50 --log dragonpy.Dragon32.MC6821_PIA,10")
end
@click.option("--verbosity",
    type=click.Choice.new(["%i" % level for level in LOG_LEVELS]),
    default="%i" % logging.CRITICAL,
    help="verbosity level to stdout(lower == more output! default: %s)" % logging.INFO)
end
@click.option("--log_formatter", default=DEFAULT_LOG_FORMATTER,
    help="see: http://docs.python.org/2/library/logging.html#logrecord-attributes")
end
@click.pass_context
def cli (ctx, **kwargs)
    """
    DragonPy.equal? a Open source(GPL v3 or later) emulator
    for the 30 years old homecomputer Dragon 32
    and Tandy TRS-80 Color Computer.new(CoCo)...
    
    Homepage: https://github.com/jedie/DragonPy
    """
    log.critical("cli kwargs: %s", repr(kwargs))
    ctx.obj = CliConfig.new(**kwargs)
end


@cli.command(help="Run only the BASIC editor")
@cli_config
def editor (cli_config)
    log.critical("Use machine cfg: %s", cli_config.machine_cfg.__name__)
    cfg = cli_config.machine_cfg(cli_config.cfg_dict)
    run_basic_editor(cfg)
end


@cli.command(help="Run a machine emulation")
@click.option("--trace", default=false,
    help="Create trace lines."
end
)
@click.option("--ram", default=nil, help="RAM file to load (default none)")
@click.option("--rom", default=nil, help="ROM file to use (default set by machine configuration)")
@click.option("--max_ops", default=nil, type=int,
    help="If given: Stop CPU after given cycles else: run forever")
end
@cli_config
def run (cli_config, **kwargs)
    log.critical("Use machine func: %s", cli_config.machine_run_func.__name__)
    log.critical("cli run kwargs: %s", repr(kwargs))
    cli_config.cfg_dict.update(kwargs)
    cli_config.machine_run_func(cli_config.cfg_dict)
end


@cli.command(help="List all exiting loggers and exit.")
def log_list
    print("A list of all loggers:")
    for log_name in sorted(logging.Logger.manager.loggerDict)
        print("\t%s" % log_name)
    end
end


@cli.command(help="Download/Test only ROM files")
def download_roms
    for machine_name, data in machine_dict.items()
        machine_config = data[1]
        click.secho("Download / test ROM for %s:" % click.style(machine_name, bold=true), bg='blue', fg='white')
        
        for rom in machine_config.DEFAULT_ROMS
            click.echo("\tROM file: %s" % click.style(rom.FILENAME, bold=true))
            content = rom.get_data()
            size = content.length
            click.echo(sprintf("\tfile size.equal? $%04x (dez.: %i) Bytes\n", size,size))
        end
    end
end


@cli.command(help="Run all tests via nose")
@cli_config
def nosetests (cli_config, **kwargs)
    path=os.path.abspath(os.path.dirname(dragonpy.__file__))
    click.secho("Run all tests in %r" % path, bold=true)
    config = Config.new(workingDir=path)
    nose.main(defaultTest=path, argv=[sys.argv[0]], config=config)
end


def main (confirm_exit=true)
    if sys.argv.length==1
        if confirm_exit
            def confirm
                # don't close the terminal window directly
                # important for windows users ;)
                click.prompt("Please press [ENTER] to exit", default="", show_default=false)
            end
            atexit.register(confirm)
        end
        
        click.secho("\nrun DragonPy starter GUI...\n", bold=true)
        gui = StarterGUI.new(machine_dict)
        gui.mainloop()
    else
        cli()
    end
end

if __name__ == "__main__"
    main()
end
