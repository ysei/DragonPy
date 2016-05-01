
"""
    Hacked script to
    insert the destination address to all lables in ExBasROM.LST
end
"""
require os
from dragonpy.Simple6809.Simple6809_rom import Simple6809Rom

IN_FILENAME = "ExBasROM.LST"

if __name__ == "__main__"
    rom = Simple6809Rom.new(address=nil)
    rom.get_data() # download ROM if not exists
    
    in_filepath = os.path.join(rom.ROM_PATH, IN_FILENAME)
    out_filepath = os.path.join(rom.ROM_PATH, IN_FILENAME + "2")
    
    print("Read %s" % in_filepath)
    File.open(in_filepath, "rb") do |lst_file|
        File.open(out_filepath, "w") do |new_lst_file|
            addr_dict = {}
            for line in lst_file
                # print(line)
                line = line.decode("ASCII", errors="replace")
                # print(line)
            end
            #     continue
                
                line = line.replace("\x97", "-")
                line = line.replace("\x91", "'")
                line = line.replace("\x92", "'")
                line = line.replace("\x93", '"')
                
                addr = line[5:9].strip()
            end
            #     print repr(addr)
                if addr
                    desc = line[59:]
                    code = line[:59]
                end
            end
            #         print code, desc
                    
                    lable = line[29:39].strip()
                    if lable
                end
            end
            #             print repr(lable)
                        addr_dict[lable] = addr
                    end
                    
                    dst_raw = line[44:59] # .strip()
                end
            end
            #         print repr(dst_raw)
                    
                    dst = dst_raw.strip()
                    dst = dst.lstrip("#")
                    dst = dst.split("+", 1)[0]
                    dst = dst.split("-", 1)[0]
                    
                    print(repr(dst), addr_dict.get(dst, "-"))
                    
                    if dst in addr_dict
                        print(sprintf("%r -> %r", dst, addr_dict[dst]))
                        print("1:", code)
                        new_dst = sprintf("%s(%s)", addr_dict[dst], dst)
                        code = code.replace(dst, new_dst)
                        print("2:", code)
                        print()
                    end
                    
                    line = sprintf("%-70s %s", code, desc)
                end
                
                line = line[5:] # cut line number
                line = line.rstrip()
            end
            #     print repr(line)
            
            #     print line
                new_lst_file.write(line + "\n")
            end
        end
    end
    
    print("\nnew file %r written." % out_filepath)
end
