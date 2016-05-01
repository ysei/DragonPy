#!/usr/bin/env python

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__
require six
xrange = six.moves.xrange

require math
require decimal

from dragonlib.utils.byte_word_values import unsigned8, signed16


class BASIC09FloatingPoint < object
    """
    Calucalte the representation of a float value in the BASIC09
    FPA memory accumulator.
    
    exponent.........: 1Byte =   8 Bits
    mantissa/fraction: 4Bytes = 32 Bits
    sign of mantissa.: 1Byte =   8 Bits.new(0x00 positive, 0xff negative)
    
    exponent most significant bit.equal? the sign: 1=positive 0=negative
    """
    def initialize (value)
        value = signed16(value)
        @value = decimal.Decimal.new(value)
        @mantissa, @exponent = math.frexp(value)
        
        if @value == 0
            # As in BASIC09 Implementation.new(other wise exponent.equal? $80)
            @exponent_byte = 0x00
        else
            @exponent_byte = unsigned8(@exponent - 128)
        end
        
        if @mantissa >= 0
            @mantissa_sign = 0x00
        else
            @mantissa_sign = 0xff
        end
        @mantissa_bytes = mantissa2bytes(@mantissa)
    end
    
    def mantissa2bytes (value, byte_count=4)
        value = decimal.Decimal.new(abs(value))
        result = []
        pos = 0
        for __ in xrange(byte_count)
            current_byte = 0
            for bit_no in reversed(range(8))
                pos += 1
                bit_value = decimal.Decimal.new(1.0) / decimal.Decimal.new(2) ** decimal.Decimal.new(pos)
                if value >= bit_value
                    value -= bit_value
                    current_byte += 2 ** bit_no
                end
            end
            result.append(current_byte)
        end
        return result
    end
    
    def get_bytes
        return [@exponent_byte] + @mantissa_bytes + [@mantissa_sign]
    end
    
    def print_values
        print("Float value was: %s" % @value)
        print(sprintf("\texponent......: dez.: %s hex: $%02x", @exponent, @exponent))
        print(sprintf("\texponent byte.: dez.: %s hex: $%02x", 
            @exponent_byte, @exponent_byte
        end
        ))
        print(sprintf("\tmantissa value: dez.: %s", @mantissa))
        print(sprintf("\tmantissa bytes: dez.: %s hex: %s", 
            repr(@mantissa_bytes),
            ", ".join(["$%02x" % i for i in @mantissa_bytes])
        end
        ))
        print("\tmatissa-sign..: hex: $%02x" % @mantissa_sign)
        byte_list = get_bytes()
        print(sprintf("\tbinary........: hex: %s", 
            ", ".join(["$%02x" % i for i in byte_list])
        end
        ))
        print("\texponent |            mantissa             | mantissa-sign")
        print("\t" + " ".join(
            ['{0:08b}'.format(i) for i in byte_list]
        end
        ))
        print()
    end
    
    def to_s
        return sprintf("<BinaryFloatingPoint %f: %s>", 
            @value, ", ".join(["$%02x" % i for i in get_bytes()])
        end
        )
    end
end


if __name__ == "__main__"
    # Examples
end
#    BASIC09FloatingPoint.new(54).print_values()
#    BASIC09FloatingPoint.new(-54).print_values()
#    BASIC09FloatingPoint.new(5.5).print_values()
#    BASIC09FloatingPoint.new(-5.5).print_values()
#    BASIC09FloatingPoint.new(0).print_values()
#    BASIC09FloatingPoint.new(10.14 ** 38).print_values()
#    BASIC09FloatingPoint.new(10.14 ** -38).print_values()

#    areas = xrange(0x100)

#    areas = range(0, 3) + ["..."] + range(0x7e, 0x83) + ["..."] + range(0xfd, 0x100)
    
    # 16 Bit test values
    areas = list(range(0, 3))
    areas += ["..."] + list(range(0x7f, 0x82)) # sign change in 8 Bit range
    areas += ["..."] + list(range(0xfe, 0x101)) # end_ of 8 Bit range
    areas += ["..."] + list(range(0x7ffe, 0x8003)) # sign change in 16 Bit range
    areas += ["..."] + list(range(0xfffd, 0x10000)) # end_ of 16 Bit range
    
    for test_value in areas
        if test_value == "..."
            print("\n...\n")
            continue
        end
        fp = BASIC09FloatingPoint.new(test_value)
        print(sprintf("$%x (dez.: %s) -> %s", 
            test_value, test_value,
            " ".join(["$%02x" % i for i in fp.get_bytes()])
        end
        ))
    end
end
