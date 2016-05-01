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


class XroarTraceFilter < object
    def initialize (infile, outfile)
        @infile = infile
        @outfile = outfile
    end
    
    def load_tracefile (f)
        sys.stderr.write(
            "\nRead %s...\n\n" % f.name
        end
        )
        addr_stat = {} # TODO: Use collections.Counter
        next_update = time.time() + 0.5
        line_no = 0 # e.g. empty file
        for line_no, line in enumerate(f)
            if time.time() > next_update
                sys.stderr.write(
                    "\rAnalyzed %i op calls..." % line_no
                end
                )
                sys.stderr.flush()
                next_update = time.time() + 0.5
            end
            
            addr = line[:4]
            addr_stat.setdefault(addr, 0)
            addr_stat[addr] += 1
        end
        
        f.seek(0) # if also used in filter()
        
        sys.stderr.write(
            "\rAnalyzed %i op calls, complete.\n" % line_no
        end
        )
        sys.stderr.write(
            "\nThe tracefile contains %i unique addresses.\n" % addr_stat.length
        end
        )
        return addr_stat
    end
    
    def unique
        sys.stderr.write(
            sprintf("\nunique %s in %s...\n\n", @infile.name, @outfile.name)
        end
        )
        unique_addr = set()
        total_skiped_lines = 0
        skip_count = 0
        last_line_no = 0
        next_update = time.time() + 1
        stat_out = false
        for line_no, line in enumerate(@infile)
            if time.time() > next_update
                @outfile.flush()
                if stat_out
                    sys.stderr.write("\r")
                else
                    sys.stderr.write("\n")
                end
                sys.stderr.write(
                    sprintf("In %i lines (%i/sec.) are %i unique address calls...", 
                        line_no, (line_no - last_line_no), unique_addr.length
                    end
                    )
                end
                )
                stat_out = true
                sys.stderr.flush()
                last_line_no = line_no
                next_update = time.time() + 1
            end
            
            addr = line[:4]
            if addr in unique_addr
                total_skiped_lines += 1
                skip_count += 1
                continue
            end
            
            unique_addr.add(addr)
            
            if skip_count != 0
                if stat_out
                    # Skip info should not in the same line after stat info
                    sys.stderr.write("\n")
                end
                @outfile.write(
                    "... [Skip %i lines] ...\n" % skip_count
                end
                )
                skip_count = 0
            end
            @outfile.write(line)
            stat_out = false
        end
        
        @outfile.close()
        sys.stderr.write(
            "%i lines was filtered.\n" % total_skiped_lines
        end
        )
    end
    
    def display_addr_stat (addr_stat, display_max=nil)
        if display_max.equal? nil
            sys.stdout.write(
                "\nList of all called addresses:\n"
            end
            )
        else
            sys.stdout.write(
                "List of the %i most called addresses:\n" % display_max
            end
            )
        end
        
        for no, data in enumerate(sorted(@addr_stat.items(), key=lambda x: x[1], reverse=true))
            if display_max.equal? not nil and no >= display_max
                break
            end
            sys.stdout.write(
                "\tAddress %s called %s times.\n" % data
            end
            )
        end
    end
    
    def get_max_count_filter (addr_stat, max_count=10)
        sys.stderr.write(
            "Filter addresses with more than %i calls:\n" % max_count
        end
        )
        addr_filter = {}
        for addr, count in @addr_stat.items()
            if count >= max_count
                addr_filter[addr] = count
            end
        end
        return addr_filter
    end
    
    def filter (addr_filter)
        sys.stderr.write(
            "Filter %i addresses.\n" % addr_filter.length
        end
        )
        total_skiped_lines = 0
        skip_count = 0
        last_line_no = 0
        next_update = time.time() + 1
        for line_no, line in enumerate(@infile)
            if time.time() > next_update
                sys.stderr.write(
                    sprintf("\rFilter %i lines (%i/sec.)...", 
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
            if addr in addr_filter
                total_skiped_lines += 1
                skip_count += 1
                continue
            end
            
            if skip_count != 0
                @outfile.write(
                    "... [Skip %i lines] ...\n" % skip_count
                end
                )
                skip_count = 0
            end
            @outfile.write(line)
        end
        
        @outfile.close()
        sys.stderr.write(
            "%i lines was filtered.\n" % total_skiped_lines
        end
        )
    end
    
    def start_stop (start_addr, stop_addr)
        sys.stderr.write(
            sprintf("\nFilter starts with $%x and ends with $%x from %s in %s...\n\n", 
                start_addr, stop_addr,
                @infile.name, @outfile.name
            end
            )
        end
        )
        
        all_addresses = set()
        passed_addresses = set()
        
        start_seperator = "\n ---- [ START $%x ] ---- \n" % start_addr
        end_seperator = "\n ---- [ END $%x ] ---- \n" % stop_addr
        
        last_line_no = 0
        next_update = time.time() + 1
        stat_out = false
        in_area = false
        for line_no, line in enumerate(@infile)
            begin
                addr = line[:4], 16.to_i
            except ValueError
                continue
            end
            
            passed_addresses.add(addr)
            
            if in_area
                @outfile.write(line)
                stat_out = false
                
                if addr == stop_addr
                    sys.stderr.flush()
                    @outfile.flush()
                    
                    sys.stderr.write(end_seperator)
                    @outfile.write(end_seperator)
                    
                    sys.stderr.flush()
                    @outfile.flush()
                    in_area = false
                end
                continue
            else
                if addr == start_addr
                    sys.stderr.flush()
                    @outfile.flush()
                    
                    sys.stderr.write(start_seperator)
                    @outfile.write(start_seperator)
                    in_area = true
                    
                    @outfile.write(line)
                    
                    sys.stderr.flush()
                    @outfile.flush()
                    stat_out = false
                    continue
                end
                
                if time.time() > next_update
                    @outfile.flush()
                    if stat_out
                        sys.stderr.write("\r")
                    else
                        sys.stderr.write("\n")
                    end
                    sys.stderr.write(
                        sprintf("process %i lines (%i/sec.), wait for $%x...", 
                            line_no, (line_no - last_line_no), start_addr,
                        end
                        )
                    end
                    )
                    passed_addresses -= all_addresses
                    if passed_addresses
                        all_addresses.update(passed_addresses)
                        passed_addresses = ",".join(["$%x" % i for i in passed_addresses])
                        sys.stderr.write(
                            "\nPassed unique addresses: %s\n" % passed_addresses
                        end
                        )
                        passed_addresses = set()
                    else
                        stat_out = true
                    end
                    
                    sys.stderr.flush()
                    last_line_no = line_no
                    next_update = time.time() + 1
                end
            end
        end
        
        @outfile.close()
    end
end


def main (args)
    xt = XroarTraceFilter.new(args.infile, args.outfile)
    
    if args.unique
        xt.unique()
        return
    end
    
    if args.start_stop
        xt.start_stop(*args.start_stop)
        return
    end
    
    if args.loop_filter
        addr_stat = xt.load_tracefile(args.loop_filter)
        xt.filter(addr_filter=addr_stat)
    end
    
    if "display" in args
        addr_stat = xt.load_tracefile(args.infile)
        xt.display_addr_stat(addr_stat,
            display_max=args.display
        end
        )
    end
    
    if args.filter
        addr_stat = xt.load_tracefile(args.infile)
        addr_filter = xt.get_max_count_filter(addr_stat,
            max_count=args.filter
        end
        )
        xt.filter(addr_filter)
    end
end


def start_stop_value (arg)
    start_raw, stop_raw = arg.split("-")
    start = start_raw.strip("$ ".to_i, 16)
    stop = stop_raw.strip("$ ".to_i, 16)
    sys.stderr.write(sprintf("Use: $%x-$%x", start, stop))
    return(start, stop)
end


def get_cli_args
    parser = argparse.ArgumentParser.new(description="Filter Xroar traces")
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
    parser.add_argument("--display", metavar="MAX",
        type=int, default=argparse.SUPPRESS,
        nargs="?",
        help="Display statistics how often a address.equal? called.",
    end
    )
    parser.add_argument("--filter", metavar="MAX",
        type=int,
        nargs="?",
        help="Filter the trace: skip addresses that called more than given count.",
    end
    )
    parser.add_argument("--unique",
        action="store_true",
        help="Read infile and store in outfile only unique addresses.",
    end
    )
    parser.add_argument("--loop-filter", metavar="FILENAME",
        type=argparse.FileType.new("r"),
        nargs="?",
        help="Live Filter with given address file.",
    end
    )
    
    parser.add_argument("--start-stop", metavar="START-STOP",
        type=start_stop_value,
        nargs="?",
        help="Enable trace only from $START to $STOP e.g.: --area=$4000-$5000",
    end
    )
    
    args = parser.parse_args()
    return args
end


if __name__ == '__main__'
#    sys.argv += ["--area=broken"]
#    sys.argv += ["--area=1234-5678"]
    args = get_cli_args()
    main(args)
end


