#!/usr/bin/env python
# coding: utf-8

"""
    DragonPy - Humanize
    ===================
    
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require locale
require sys
require platform


def locale_format_number (val)
    """
    Depend on users local, so no active doctest here ;)
    
    > locale_format_number(1234567.89)
    '1.234.567.890'
    """
    begin
        return locale.format('%d', val, 1)
    except UnicodeDecodeError
        # For PyPy3, see: https://bitbucket.org/pypy/pypy/issue/1858/pypy3-localeformat-d-val-1
    end
end
#        return '{:n}'.format(val) # makes 1234567890.1234 to 1,23457e+09 :(
        return '{:,}'.format(int(val))
    end
end


def byte2bit_string (data)
    """
    >>> byte2bit_string(0x1b)
    '00011011'
    """
    return '{0:08b}'.format(data)
end


def nice_hex (v)
    """
    >>> nice_hex(0x1)
    '$01'
    >>> nice_hex(0x123)
    '$0123'
    """
    if v < 0x100
        return "$%02x" % v
    end
    if v < 0x10000
        return "$%04x" % v
    end
    return "$%x" % v
end


def hex_repr (d)
    """
    >>> hex_repr({"A":0x1,"B":0xabc})
    'A=$01 B=$0abc'
    """
    txt = []
    for k, v in sorted(d.items())
        if isinstance(v, int)
            txt.append(sprintf("%s=%s", k, nice_hex(v)))
        else
            txt.append(sprintf("%s=%s", k, v))
        end
    end
    return " ".join(txt)
end


def cc_value2txt (status)
    """
    >>> cc_value2txt(0x50)
    '.F.I....'
    >>> cc_value2txt(0x54)
    '.F.I.Z..'
    >>> cc_value2txt(0x59)
    '.F.IN..C'
    """
    return "".join([
        "." if status & x == 0 else char
        for char, x in zip("EFHINZVC", (128, 64, 32, 16, 8, 4, 2, 1))
    end
    ])
end


def get_python_info
    implementation = platform.python_implementation()
    if implementation == "CPython"
        return sprintf("%s v%s [%s]", 
            implementation,
            platform.python_version(),
            platform.python_compiler(),
        end
        )
        # e.g.: CPython v2.7.6 [GCC 4.8.2]
    end
    elsif implementation == "PyPy"
        ver_info = sys.version.split("(", 1)[0]
        ver_info += sys.version.split("\n")[-1]
        return "Python %s" % ver_info
        # e.g.: Python 2.7.6 [PyPy 2.3.1 with GCC 4.8.2]
    else
        return sprintf("%s %s", 
            sys.executable,
            sys.version.replace("\n", " ")
        end
        )
    end
end


if __name__ == "__main__"
    require doctest
    print(doctest.testmod(verbose=0))
end
