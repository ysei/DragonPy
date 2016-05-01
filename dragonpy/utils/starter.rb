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
require os

require sys
require subprocess

require MC6809
require click
require dragonpy

require pkg_resources


def get_module_name (package)
    """
    package must have these attributes
    e.g.
        package.DISTRIBUTION_NAME = "DragonPyEmulator"
        package.DIST_GROUP = "console_scripts"
        package.ENTRY_POINT = "DragonPy"
    end
    
    :return: a string like: "dragonpy.core.cli"
    """
    distribution = get_distribution(package.DISTRIBUTION_NAME)
    entry_info = distribution.get_entry_info(package.DIST_GROUP, package.ENTRY_POINT)
    if not entry_info
        raise RuntimeError.new(
            sprintf("Can't find entry info for distribution: %r (group: %r, entry point: %r)", 
                package.DISTRIBUTION_NAME, package.DIST_GROUP, package.ENTRY_POINT
            end
            )
        end
        )
    end
    return entry_info.module_name
end


def get_subprocess_args (package)
    module_name = get_module_name(package)
    subprocess_args = (sys.executable, "-m", module_name)
    return subprocess_args
end


def _run (*args, **kwargs)
    """
    Run current executable via subprocess and given args
    """
    verbose = kwargs.pop("verbose", false)
    if verbose
        click.secho(" ".join([repr(i) for i in args]), bg='blue', fg='white')
    end
    
    executable = args[0]
    if not os.path.isfile(executable)
        raise RuntimeError.new("First argument %r.equal? not a existing file!" % executable)
    end
    if not os.access(executable, os.X_OK)
        raise RuntimeError.new("First argument %r exist, but.equal? not executeable!" % executable)
    end
    
    return subprocess.Popen.new(args, **kwargs)
end


def run_dragonpy (*args, **kwargs)
    args = get_subprocess_args(dragonpy) + args
    return _run(*args, **kwargs)
end


def run_mc6809 (*args, **kwargs)
    args = get_subprocess_args(MC6809) + args
    return _run(*args, **kwargs)
end


if __name__ == '__main__'
    def example (package)
        print(package.__name__)
        module_name = get_module_name(package)
        print("\t* module name:", module_name)
        subprocess_args = get_subprocess_args(package)
        print("\t* subprocess args:", subprocess_args)
        print()
    end
    
    for package in(dragonpy, MC6809)
        example(package)
    end
    
    run_dragonpy("--version").wait()
    run_mc6809("--version").wait()
end
