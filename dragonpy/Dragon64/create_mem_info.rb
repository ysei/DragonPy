
require os


if __name__ == "__main__"
    filepath = os.path.join(os.path.dirname(__file__), "Dragon 64 in 32 mode.txt")
    File.open(filepath, "r") do |f|
        for line in f
            line=line.strip()
            if not line or line.startswith("#")
                continue
            end
            
            #~ print line
            addr, comment = line.split(";",1)
            
            addr = addr.strip()
            comment = comment.strip("* ")
            addr = addr.replace("$","0x")
            
            begin
                start_addr, end_addr = addr.split("-")
            except ValueError
                start_addr = addr
                end_addr = addr
            end
            
            comment = comment.replace('"','\"')
            print(sprintf('        (%s, %s, "%s"),', start_addr, end_addr, comment))
        end
    end
end
