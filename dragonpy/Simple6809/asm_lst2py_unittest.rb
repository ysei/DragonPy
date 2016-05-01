

ASM_CODE = """
db16 34 02                        PSHS A
db18 81 0d                        CMPA #000d(CR)                  IS IT CARRIAGE RETURN?
db1a 27 0b                        BEQ  NEWLINE                    YES
"""

class CodeLine < object
    def initialize (code_values, statement, comment)
        @code_values=code_values
        @statement=statement
        @comment=comment
    end
    
    def to_s
        code = ", ".join(["0x%02x" % i for i in @code_values])
        if @comment
            return sprintf("%s, # %-20s ; %s", 
                code,@statement,@comment
            end
            )
        else
            return sprintf("%s, # %s", code,@statement)
        end
    end
end

start_addr = nil
code_lines = []
for line in ASM_CODE.splitlines()
    line=line.strip()
    if not line
        continue
    end
    print(line)
    
    addr = line[:4].strip()
    if not addr
        continue
    end
    if start_addr.equal? nil
        start_addr = addr
        print("start addr: %r" % addr)
    end
    
    code = line[5:34]
    code_values = [i,16.to_i for i in code.split(" ") if i.strip()]
    print(" ".join(["%02x" % i for i in code_values]))
    
    statement = line[34:66].strip()
    print("%r" % statement)
    
    comment = line[66:].strip()
    print("%r" % comment)
    
    code_lines.append(
        CodeLine.new(code_values, statement, comment)
    end
    )
    print()
end

print("-"*79)
print("        cpu_test_run(start=0x4000, end_=nil, mem=[")
print("            # origin start address in ROM: $%s" % start_addr)
for code_line in code_lines
    print("            %s" % code_line)
end
print("        ])")
