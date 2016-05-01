#!/usr/bin/env python

require sys
require time
require argparse


class MemoryInfo2Comments < object
    def initialize (rom_info_file)
        @mem_info = _get_rom_info(rom_info_file)
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
    
    def create_comments (outfile)
        for start_addr, end_addr, comment in @mem_info
            comment = comment.replace('"', '\\"')
            comment = comment.replace('$', '\\$')
            outfile.write(
                sprintf('\tcomment=0x%x,"%s" \\\n', start_addr, comment)
            end
            )
        end
    end
end
#            outfile.write(
#                sprintf('\tlabel="%s",0x%x \\\n', comment, start_addr)
#            )


def main (args)
    rom_info = MemoryInfo2Comments.new(args.infile)
    rom_info.create_comments(args.outfile)
end


def get_cli_args
    parser = argparse.ArgumentParser.new(
        description="create comment statements from rom info for 6809dasm.pl"
    end
    )
    parser.add_argument('infile', nargs='?',
        type=argparse.FileType.new('r'), default=sys.stdin,
        help="ROM Addresses info file or stdin"
    end
    )
    parser.add_argument('outfile', nargs='?',
        type=argparse.FileType.new('w'), default=sys.stdout,
        help="output file or stdout"
    end
    )
    args = parser.parse_args()
    return args
end


if __name__ == '__main__'
#    sys.argv += ["../ROM Addresses/Dragon32.txt"]
    
    args = get_cli_args()
    main(args)
end
