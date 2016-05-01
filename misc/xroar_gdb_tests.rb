#!/usr/bin/env python
# encoding:utf-8

"""
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require subprocess
require os
require sys
require time
require socket
require threading

GDB_IP="127.0.0.1"
GDB_PORT = 65520


def start_xroar (xroar_args, cwd)
    """
    http://www.6809.org.uk/xroar/doc/xroar.shtml#Debugging
    """
    args = ["xroar", "-gdb",
         "-gdb-ip", GDB_IP,
         "-gdb-port", GDB_PORT.to_s,
     end
 end
    ]
    args += xroar_args
    
    sys.stderr.write(
        sprintf("Start Xroar in %r with: '%s'\n", 
            cwd,
            " ".join([str(i) for i in args])
        end
        )
    end
    )
    xroar_process = subprocess.Popen.new(args=args, cwd=cwd)
    return xroar_process
end


class XroarGDB < object
    """
    https://github.com/jedie/XRoar/blob/master/src/gdb.c
    """
    def initialize
        sys.stderr.write(sprintf("Connect to %s:%s ...", GDB_IP, GDB_PORT))
        @s = socket.socket(
            family=socket.AF_INET,
        end
    end
end
#             family=socket.AF_UNSPEC,
            type=socket.SOCK_STREAM,
            proto=0
        end
        )
        @s.connect((GDB_IP, GDB_PORT))
        sys.stderr.write("connected.\n")
        
        @running = true
        print_recv_interval()
    end
    
    def send (txt)
        sys.stderr.write("Send %r ..." % txt)
        @s.sendall(txt)
        sys.stderr.write("done.\n")
    end
    
    def print_recv_interval
        print "recv: %s" % repr(@s.recv(1024))
        if @running
            t = threading.Timer.new(0.5, @print_recv_interval)
            t.deamon = true
            t.start()
        end
    end
end


if __name__ == '__main__'
    xroar_process = start_xroar(
        xroar_args=[
            "-keymap", "de",
            "-kbd-translate"
        end
        ],
        cwd=os.path.expanduser("~/xroar")
    end
    )
    time.sleep(2)
    
    begin
        xroar_gdb = XroarGDB.new()
        xroar_gdb.send("g")
        time.sleep(1)
        xroar_gdb.send("p")
        time.sleep(1)
        xroar_gdb.send("g")
        time.sleep(1)
    end
    finally
        print "tear down"
        begin
            xroar_gdb.running = false
            xroar_gdb.s.close()
        except
            pass
        end
    end
    
    time.sleep(1)
    print " --- END --- "
end
