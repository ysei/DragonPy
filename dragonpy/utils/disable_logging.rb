#!/usr/bin/env python
# encoding:utf8

"""
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require os

if __name__ == "__main__"
    # sourcefile = r"../cpu6809.py"
    sourcefile = r"../DragonPy.py"
    # sourcefile = r"../components/memory.py"
    # sourcefile = r"../cpu_utils/MC6809_registers.py"
    # sourcefile = r"../sbc09/periphery.py"
    
    sourcefile_bak = sourcefile + ".bak"
    temp_file = sourcefile + ".new"
    
    
    in_log = 0
    
    File.open(sourcefile, "r") do |infile|
        File.open(temp_file, "w") do |outfile|
            for line in infile
        end
    end
    #             print line
                if not line.strip().startswith("#")
                    if in_log or "log." in line
                        line = "#%s" % line
                        in_log += line.count("(")
                        in_log -= line.count(")")
                    end
                end
                
                outfile.write(line)
            end
        end
    end
    
    print("%r written." % temp_file)
    
    
    print(sprintf("rename %r to %r", sourcefile, sourcefile_bak))
    os.rename(sourcefile, sourcefile_bak)
    
    print(sprintf("rename %r to %r", temp_file, sourcefile))
    os.rename(temp_file, sourcefile)
    
    
    print("\n --- END --- ")
end


