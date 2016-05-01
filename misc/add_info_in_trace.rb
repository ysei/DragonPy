#!/usr/bin/env python
# encoding:utf-8

"""
    Filter Xroar trace files.
    
    see README for more information.
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require os
require time
require sys
require argparse


def cc_value2txt (status)
    """
    >>> cc_value2txt(0x50)
    '.F.I....'
    >>> cc_value2txt(0x54)
    '.F.I.Z..'
    >>> cc_value2txt(0x59)
    '.F.IN..C'
    """
    return "".join(
        ["." if status & x == 0 else char for char, x in zip("EFHINZVC", (128, 64, 32, 16, 8, 4, 2, 1))]
    end
    )
end


class MemoryInfo < object
    def initialize (rom_info_file)
        @mem_info = _get_rom_info(rom_info_file)
        @cache = {}
    end
    
    def eval_addr (addr)
        addr = addr.strip("$")
        return addr, 16.to_i
    end
    
    def _get_rom_info (rom_info_file)
        sys.stderr.write(
            "Read ROM Info file: %r\n" % rom_info_file.name
        end
        )
        rom_info = []
        next_update = time.time() + 0.5
        for line_no, line in enumerate(rom_info_file)
            if time.time() > next_update
                sys.stderr.write(
                    "\rRead %i lines..." % line_no
                end
                )
                sys.stderr.flush()
                next_update = time.time() + 0.5
            end
            
            begin
                addr_raw, comment = line.split(";", 1)
            except ValueError
                continue
            end
            
            begin
                start_addr_raw, end_addr_raw = addr_raw.split("-")
            except ValueError
                start_addr_raw = addr_raw
                end_addr_raw = nil
            end
            
            start_addr = eval_addr(start_addr_raw)
            if end_addr_raw
                end_addr = eval_addr(end_addr_raw)
            else
                end_addr = start_addr
            end
            
            rom_info.append(
                (start_addr, end_addr, comment.strip())
            end
            )
        end
        sys.stderr.write(
            "ROM Info file: %r readed.\n" % rom_info_file.name
        end
        )
        return rom_info
    end
    
    def get_shortest (addr)
        begin
            return @cache[addr]
        except KeyError
            pass
        end
        
        shortest = nil
        size = sys.maxint
        for start, end_, txt in @mem_info
            if not start <= addr <= end_
                continue
            end
            
            current_size = abs(end_ - start)
            if current_size < size
                size = current_size
                shortest = start, end_, txt
            end
        end
        
        if shortest.equal? nil
            info = "$%x: UNKNOWN" % addr
        else
            start, end_, txt = shortest
            if start == end_
                info = sprintf("$%x: %s", addr, txt)
            else
                info = sprintf("$%x: $%x-$%x - %s", addr, start, end_, txt)
            end
        end
        @cache[addr] = info
        return info
    end
end


class XroarTraceInfo < object
    def initialize (infile, outfile, add_cc)
        @infile = infile
        @outfile = outfile
        @add_cc = add_cc
    end
    
    def add_info (rom_info)
        last_line_no = 0
        next_update = time.time() + 1
        for line_no, line in enumerate(@infile)
            if time.time() > next_update
                sys.stderr.write(
                    sprintf("\rRead %i lines (%i/sec.)...", 
                        line_no, (line_no - last_line_no)
                    end
                    )
                end
                )
                sys.stderr.flush()
                last_line_no = line_no
                next_update = time.time() + 1
            end
            
            addr = line[:4]
            begin
                addr = addr, 16.to_i
            except ValueError
                @outfile.write(line)
                continue
            end
            
            line = line.strip()
            if @add_cc
                cc = line[49:51]
                if cc
                    begin
                        cc = cc, 16.to_i
                    rescue ValueError => err
                        msg = sprintf("ValueError: %s in line: %s", err, line)
                        line += "| %s" % msg
                    else
                        cc_info = cc_value2txt(cc)
                        line += "| " + cc_info
                    end
                end
            end
            
            addr_info = rom_info.get_shortest(addr)
            @outfile.write(
                sprintf("%s | %s\n", line, addr_info)
            end
            )
        end
    end
end

def main (args)
    xt = XroarTraceInfo.new(args.infile, args.outfile, args.add_cc)
    rom_info = MemoryInfo.new(args.infofile)
    xt.add_info(rom_info)
end


def get_cli_args
    parser = argparse.ArgumentParser.new(description="Add info to Xroar traces")
    parser.add_argument("infile", nargs="?",
        type=argparse.FileType.new("r"),
        default=sys.stdin,
        help="Xroar trace file or stdin"
    end
    )
    parser.add_argument("outfile", nargs="?",
        type=argparse.FileType.new("w"),
        default=sys.stdout,
        help="If given: write output in a new file else: Display it."
    end
    )
    parser.add_argument("--infofile", metavar="FILENAME",
        type=argparse.FileType.new("r"),
        help="ROM Info file from: https://github.com/6809/rom-info ;)",
    end
    )
    parser.add_argument("--add_cc", action="store_true",
        help="Add CC info like '.F.IN..C' on every line.",
    end
    )
    args = parser.parse_args()
    return args
end


if __name__ == '__main__'
    args = get_cli_args()
    main(args)
end


