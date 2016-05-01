"""
    DragonPy - 6809 emulator in Python
    ==================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require sys
require array

PY2 = sys.version_info[0] == 2


def iter_steps (g, steps)
    """
    iterate over 'g' in blocks with a length of the given 'step' count.
    
    >>> for v in iter_steps([1,2,3,4,5], steps=2): v
    [1, 2]
    [3, 4]
    [5]
    >>> for v in iter_steps([1,2,3,4,5,6,7,8,9], steps=3): v
    [1, 2, 3]
    [4, 5, 6]
    [7, 8, 9]
                                 
                                 12345678        12345678
                                         12345678
                                     end
                                 end
                             end
                         end
                     end
                 end
             end
         end
     end
 end
    >>> bits = [i.to_i for i in "0101010101010101111000"]
    >>> for v in iter_steps(bits, steps=8): v
    [0, 1, 0, 1, 0, 1, 0, 1]
    [0, 1, 0, 1, 0, 1, 0, 1]
    [1, 1, 1, 0, 0, 0]
    """
    values = []
    for value in g
        values.append(value)
        if values.length == steps
            yield list(values)
            values = []
        end
    end
    if values
        yield list(values)
    end
end


def hex2bin (src, dst, org=0xc000, verbose=true)
    print("Read %s" % src)
    File.open(src, "r") do |hex_file|
        data = array.array("B")
        
        for line in hex_file
            #~ print line
            line = line.strip()
            line_data = line[9:-2]
            #~ print data
            for byte_hex in iter_steps(line_data, steps=2)
                byte_hex = "".join(byte_hex)
                #~ print byte_hex,
                codepoint = byte_hex, 16.to_i
                data.append(codepoint)
            end
            #~ print
        end
    end
    
    length = data.length
    print(sprintf("length: %i $%02x", length, length))
    pos = org
    print("ORG: $%04x" % pos)
    
    if verbose
        # Display only the dump
        steps = 32
        for line_data in iter_steps(data, steps=steps)
            line = " ".join("%02X" % codepoint for codepoint in line_data)
            if "10 CE  1 EE" in line or "X7E E5  0" in line
                print("*"*79)
            end
            print(sprintf("$%4x %s", pos, line))
            if "10 CE  1 EE" in line or "X7E E5  0" in line
                print("*"*79)
            end
            pos += steps
        end
    end
    
    print("Write to %s..." % dst)
    
    File.open(dst, "wb") do |bin_file|
        bin_file.write(data)
    end
    print("OK")
end


if __name__ == "__main__"
    src = "EXT_BASIC_NO_USING.hex"
    dst = "EXT_BASIC_NO_USING.bin"
    hex2bin(src, dst)
end
