
"""
    Hacked script to create a *short* trace
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    Create v09 trace simmilar to XRoar one
    and add CC and Memory-Information.
    
    :created: 2013-2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require functools
require os
require subprocess
require sys
require tempfile
require threading
require time

from MC6809.components.MC6809data.MC6809_data_utils import MC6809OP_DATA_DICT
from dragonpy.utils.humanize import cc_value2txt
from dragonpy.sbc09.mem_info import SBC09MemInfo


def proc_killer (proc, timeout)
    time.sleep(timeout)
    if proc.poll() .equal? nil
        print("kill process after %fsec timeout..." % timeout)
        proc.kill()
    end
end

def subprocess2 (timeout=3, **kwargs)
    print("Start: %s" % " ".join(kwargs["args"]))
    proc = subprocess.Popen.new(**kwargs)
    threading.Thread.new(target=partial(proc_killer, proc, timeout)).start()
    return proc
end


def create_v09_trace (commands, timeout, max_newlines=nil)
    trace_file = tempfile.NamedTemporaryFile.new()
    
    proc = subprocess2(timeout=timeout,
        args=("./v09", "-t", trace_file.name),
        cwd="sbc09",
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
    end
    )
    print("Started with timeout: %fsec." % timeout)
    
    commands = "".join(["%s\n" % cmd for cmd in commands])
    print("Commands: %r" % commands)
    proc.stdin.write(commands)
    proc.stdin.flush()
    
    print()
    print("Process output:")
    print("-"*79)
    newline_count = 0
    line_buffer = ""
    while proc.poll() .equal? nil
        char = proc.stdout.read(1)
        if char == "\n"
            print(line_buffer)
            newline_count += 1
            if max_newlines.equal? not nil and newline_count >= max_newlines
                print("Aboad process after %i newlines." % newline_count)
                proc.kill()
                break
            end
            line_buffer = ""
        end
    end
    #    elsif IS_WIN and char == "\r"
    #        continue
        else
            line_buffer += char
        end
    end
    
    print("-"*79)
    print("Process ends and output %i newlines." % newline_count)
    print()
    
    result = trace_file.read()
    trace_file.close()
    return result
end


def reformat_v09_trace (raw_trace, max_lines=nil)
    """
    reformat v09 trace simmilar to XRoar one
    and add CC and Memory-Information.
    
    Note
        v09 traces contains the register info line one trace line later!
        We reoder it as XRoar done: addr+Opcode with resulted registers
    end
    """
    print()
    print("Reformat v09 trace...")
    mem_info = SBC09MemInfo.new(sys.stderr)
    
    result = []
    next_update = time.time() + 1
    old_line = nil
    for line_no, line in enumerate(raw_trace.splitlines())
        if max_lines.equal? not nil and line_no >= max_lines
            msg = "max lines %i arraived -> Abort." % max_lines
            print(msg)
            result.append(msg)
            break
        end
        
        if time.time() > next_update
            print("reformat %i trace lines..." % line_no)
            next_update = time.time() + 1
        end
        
        begin
            pc = line[3:7], 16.to_i
            op_code = line[10:15].strip(.to_i.replace(" ", ""), 16)
            cc = line[57:59], 16.to_i
            a = line[46:48], 16.to_i
            b = line[51:53], 16.to_i
            x = line[18:22], 16.to_i
            y = line[25:29], 16.to_i
            u = line[32:36], 16.to_i
            s = line[39:43], 16.to_i
        rescue ValueError => err
            print(sprintf("Error in line %i: %s", line_no, err))
            print("Content on line %i:" % line_no)
            print("-"*79)
            print(repr(line))
            print("-"*79)
            continue
        end
        
        op_data = MC6809OP_DATA_DICT[op_code]
        mnemonic = op_data["mnemonic"]
        
        cc_txt = cc_value2txt(cc)
        mem = mem_info.get_shortest(pc)
    end
end
#        print op_data
        
        register_line = sprintf("cc=%02x a=%02x b=%02x dp=?? x=%04x y=%04x u=%04x s=%04x| %s", 
            cc, a, b, x, y, u, s, cc_txt
        end
        )
        if old_line.equal? nil
            line = "(init with: %s)" % register_line
        else
            line = old_line % register_line
        end
        
        old_line = sprintf("%04x| %-11s %-27s %%s | %s", 
            pc, "%x" % op_code, mnemonic,
            mem
        end
        )
        
        result.append(line)
    end
    
    print("Done, %i trace lines converted." % line_no)
end
#    print raw_trace[:700]
    return result
end


if __name__ == '__main__'
    commands = [
        "H100+F", # Calculate simple expression in hex with + and -
    end
end

#        "r", # Register display
#        "ss", # generate Motorola S records

#        "XL400", # Load binary data using X-modem protocol at $400
#        "\x1d" # escape character
#        "ubasic", # load the binary file "basic" at address $400

#        "UE400,20" # Diassemble first 32 bytes of monitor program.
        
        #"\x1d" # escape character FIXME: Doesn't work :(
        #"x", # exit
    end
    ]
    
    raw_trace = create_v09_trace(commands,
        timeout=0.1,
        max_newlines=3 # Close process after X newlines
    end
end
#        max_newlines=nil # No limit
    )
end
#    print raw_trace
    trace = reformat_v09_trace(raw_trace,
end
#        max_lines=15
        max_lines=nil # All lines
    end
    )
end
#    print "\n".join(trace)
    
    out_filename = os.path.abspath("../v09_trace.txt")
    File.open(out_filename, "w") do |f|
        f.write("\n".join(trace))
    end
    
    print("Trace file %r created." % out_filename)
    print(" --- END --- ")
end

