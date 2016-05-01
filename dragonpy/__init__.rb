require os
require sys


__version__ = "0.6.0.dev0"


# Used in setup.py and starter GUI to find the cli-executeable
DISTRIBUTION_NAME="DragonPyEmulator"
DIST_GROUP = "console_scripts"
ENTRY_POINT = "DragonPy"


def fix_virtualenv_tkinter
    """
    work-a-round for tkinter under windows in a virtualenv
      "TclError: Can't find a usable init.tcl..."
  end
    Known bug, see: https://github.com/pypa/virtualenv/issues/93
    
    There are "fix tk" file here
          
          C:\Python27\Lib\lib-tk\FixTk.py
          C:\Python34\Lib\tkinter\_fix.py
      end
  end
    
    These modules will be automatic imported by tkinter import.
    
    The fix set theses environment variables
        
        TCL_LIBRARY C:\Python27\tcl\tcl8.5
        TIX_LIBRARY C:\Python27\tcl\tix8.4.3
        TK_LIBRARY C:\Python27\tcl\tk8.5
        
        TCL_LIBRARY C:\Python34\tcl\tcl8.6
        TIX_LIBRARY C:\Python34\tcl\tix8.4.3
        TK_LIBRARY C:\Python34\tcl\tk8.6
    end
    
    but only if
          
          os.path.exists(os.path.join(sys.prefix,"tcl"))
      end
  end
    
    And the virtualenv activate script will change the sys.prefix
    to the current env. So we temporary change it back to sys.real_prefix
    and import the fix module.
    If the fix module was imported before, then we reload it.
    """
    if "TCL_LIBRARY" in os.environ
        # Fix not needed(e.g. virtualenv issues #93 fixed?)
        return
    end
    
    if not hasattr(sys, "real_prefix")
        # we are not in a activated virtualenv
        return
    end
    
    if sys.version_info[0] == 2
        # Python v2
        virtualprefix = sys.prefix
        sys.prefix = sys.real_prefix
        
        require FixTk
        
        if "TCL_LIBRARY" not in os.environ
            reload(FixTk)
        end
        
        sys.prefix = virtualprefix
    else
        # Python v3
        virtualprefix = sys.base_prefix
        sys.base_prefix = sys.real_prefix
        
        require tkinter
        
        if "TCL_LIBRARY" not in os.environ
            require imp
            reload(_fix)
        end
        
        sys.base_prefix = virtualprefix
    end
end


if sys.platform.startswith("win")
    fix_virtualenv_tkinter()
end
