
"""
    6809 instruction set data
    ~~~~~~~~~~~~~~~~~~~~~~~~~

    data from:
        * http://www.maddes.net/m6809pm/sections.htm#sec4_4
        * http://www.burgins.com/m6809.html
        * http://www.maddes.net/m6809pm/appendix_a.htm#appA

    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
"""
import pprint
import sys

from appendix_a import INSTRUCTION_INFO

INSTRUCTION_INFO.update({
    'PAGE': {'addressing mode': 'VARIANT', 'description': 'Page 1/2 instructions'},
    'RESET': {'addressing mode': 'INHERENT',
        'description': ' Build the ASSIST09 vector table and setup monitor defaults, then invoke the monitor startup routine.'
    },
})

OpDescriptions = {}
categories = {
    0: "8-Bit Accumulator and Memory Instructions",
    1: "16-Bit Accumulator and Memory Instructions Instruction",
    2: "Index/Stack Pointer Instructions",
    3: "Simple Branch Instructions",
    4: "Signed Branch Instructions",
    5: "Unsigned Branch Instructions",
    6: "other Branch Instructions",
    7: "Miscellaneous Instructions",
    8: "other",
}

OTHER_INSTRUCTIONS = "OTHER_INSTRUCTIONS"
CHANGE_INSTRUCTIONS = {
    "PAGE1+": "PAGE",
    "PAGE2+": "PAGE",
    "SWI2": "SWI",
    "SWI3": "SWI",
    "RESET*": "RESET",
}
CHANGED_INSTRUCTIONS = tuple(CHANGE_INSTRUCTIONS.values())

ADDR_MODES = {
    "IMMEDIATE": 0,
    "DIRECT": 1,
    "INDEXED": 2,
    "EXTENDED": 3,
    "INHERENT": 4,
    "RELATIVE": 5,
    "VARIANT": 6,
}

INSTRUCTIONS = (
    "ABX", "ADC", "ADD", "AND", "ASL", "ASR", "BIT", "CLR", "CMP", "COM", "CWAI",
    "DAA", "DEC", "EOR", "EXG", "INC", "JMP", "JSR", "LD", "LEA", "LSL", "LSR",
    "MUL", "NEG", "NOP", "OR", "PSH", "PUL", "ROL", "ROR", "RTI", "RTS",
    "SBC", "SEX", "ST", "SUB", "SWI", "SYNC", "TFR", "TST",
    "PAGE"
)
OPERANTS = (
    "X", "Y", # 16 bit index register X,Y
    "U", "S", # 16 bit stack pointer registers U,S
    "A", "B", # 8 bit accumulator A,B
    "D", # 16 bit concatenated reg. (A + B)
    "CC", # condition code register
)

#------------------------------------------------------------------------------


#------------------------------------------------------------------------------


illegal = []

def add(category_id, txt):
    for line in txt.splitlines():
        line = line.strip()
        if not line:
            continue
        ops, desc = line.split("\t")
        ops = [o.strip() for o in ops.split(",")]
        for op in ops:
            OpDescriptions[op] = (category_id, desc)


add(0, """ADCA, ADCB	Add memory to accumulator with carry
ADDA, ADDB	Add memory to accumulator
ANDA, ANDB	AND memory with accumulator
ASL, ASLA, ASLB	Arithmetic shift of accumulator or memory left
ASR, ASRA, ASRB	Arithmetic shift of accumulator or memory right
BITA, BITB	Bit test memory with accumulator
CLR, CLRA, CLRB	Clear accumulator or memory location
CMPA, CMPB	Compare memory from accumulator
COM, COMA, COMB	Complement accumulator or memory location
DAA	Decimal adjust A accumulator
DEC, DECA, DECB	Decrement accumulator or memory location
EORA, EORB	Exclusive OR memory with accumulator
EXG 	Exchange Rl with R2
INC, INCA, INCB	Increment accumulator or memory location
LDA, LDB	Load accumulator from memory
LSL, LSLA, LSLB	Logical shift left accumulator or memory location
LSR, LSRA, LSRB	Logical shift right accumulator or memory location
MUL	Unsigned multiply (A * B ? D)
NEG, NEGA, NEGB	Negate accumulator or memory
ORA, ORB	OR memory with accumulator
ROL, ROLA, ROLB	Rotate accumulator or memory left
ROR, RORA, RORB	Rotate accumulator or memory right
SBCA, SBCB	Subtract memory from accumulator with borrow
STA, STB	Store accumulator to memroy
SUBA, SUBB	Subtract memory from accumulator
TST, TSTA, TSTB	Test accumulator or memory location
TFR 	Transfer R1 to R2
""")

add(1, """
ADDD	Add memory to D accumulator
CMPD	Compare memory from D accumulator
LDD	Load D accumulator from memory
SEX	Sign Extend B accumulator into A accumulator
STD	Store D accumulator to memory
SUBD	Subtract memory from D accumulator
""")

add(2, """
CMPS, CMPU	Compare memory from stack pointer
CMPX, CMPY	Compare memory from index register
LEAS, LEAU	Load effective address into stack pointer
LEAX, LEAY	Load effective address into index register
LDS, LDU	Load stack pointer from memory
LDX, LDY	Load index register from memory
PSHS	Push A, B, CC, DP, D, X, Y, U, or PC onto hardware stack
PSHU	Push A, B, CC, DP, D, X, Y, S, or PC onto user stack
PULS	Pull A, B, CC, DP, D, X, Y, U, or PC from hardware stack
PULU	Pull A, B, CC, DP, D, X, Y, S, or PC from hardware stack
STS, STU	Store stack pointer to memory
STX, STY	Store index register to memory
ABX	Add B accumulator to X (unsigned)
""")

add(3, """
BEQ, LBEQ	Branch if equal
BNE, LBNE	Branch if not equal
BMI, LBMI	Branch if minus
BPL, LBPL	Branch if plus
BCS, LBCS	Branch if carry set
BCC, LBCC	Branch if carry clear
BVS, LBVS	Branch if overflow set
BVC, LBVC	Branch if overflow clear
""")

add(4, """
BGT, LBGT	Branch if greater (signed)
BVS, LBVS	Branch if invalid twos complement result
BGE, LBGE	Branch if greater than or equal (signed)
BEQ, LBEQ	Branch if equal
BNE, LBNE	Branch if not equal
BLE, LBLE	Branch if less than or equal (signed)
BVC, LBVC	Branch if valid twos complement result
BLT, LBLT	Branch if less than (signed)
""")

add(5, """
BHI, LBHI	Branch if higher (unsigned)
BCC, LBCC	Branch if higher or same (unsigned)
BHS, LBHS	Branch if higher or same (unsigned)
BEQ, LBEQ	Branch if equal
BNE, LBNE	Branch if not equal
BLS, LBLS	Branch if lower or same (unsigned)
BCS, LBCS	Branch if lower (unsigned)
BLO, LBLO	Branch if lower (unsigned)
""")

add(6, """
BSR, LBSR	Branch to subroutine
BRA, LBRA	Branch always
BRN, LBRN	Branch never
""")

add(7, """
ANDCC	AND condition code register
CWAI	AND condition code register, then wait for interrupt
NOP	No operation
ORCC	OR condition code register
JMP	Jump
JSR	Jump to subroutine
RTI	Return from interrupt
RTS	Return from subroutine
SWI, SWI2, SWI3	Software interrupt (absolute indirect)
SYNC	Synchronize with interrupt line
""")

txt = """ +-----------------------------------------------------------------+
 |                       Page 0 Instructions                       |
 +------------+-------------+--------------+---------------+-------+
 | Opcode     |             | Addressing   |               |       |
 | Hex   Dec  | Instruction | Mode         | Cycles  Bytes | HNZVC |
 +------------+-------------+--------------+-------+-------+-------+
 | 00    0000 | NEG         | DIRECT       |   6   |   2   | uaaaa |
 | 01    0001 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 02    0002 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 03    0003 | COM         | DIRECT       |   6   |   2   | -aa01 |
 | 04    0004 | LSR         | DIRECT       |   6   |   2   | -0a-s |
 | 05    0005 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 06    0006 | ROR         | DIRECT       |   6   |   2   | -aa-s |
 | 07    0007 | ASR         | DIRECT       |   6   |   2   | uaa-s |
 | 08    0008 | LSL/ASL     | DIRECT       |   6   |   2   | naaas |
 | 09    0009 | ROL         | DIRECT       |   6   |   2   | -aaas |
 | 0A    0010 | DEC         | DIRECT       |   6   |   2   | -aaa- |
 | 0B    0011 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 0C    0012 | INC         | DIRECT       |   6   |   2   | -aaa- |
 | 0D    0013 | TST         | DIRECT       |   6   |   2   | -aa0- |
 | 0E    0014 | JMP         | DIRECT       |   3   |   2   | ----- |
 | 0F    0015 | CLR         | DIRECT       |   6   |   2   | -0100 |
 | 10    0016 | PAGE1+      | VARIANT      |   1   |   1   | +++++ |
 | 11    0017 | PAGE2+      | VARIANT      |   1   |   1   | +++++ |
 | 12    0018 | NOP         | INHERENT     |   2   |   1   | ----- |
 | 13    0019 | SYNC        | INHERENT     |   2   |   1   | ----- |
 | 14    0020 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 15    0021 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 16    0022 | LBRA        | RELATIVE     |   5   |   3   | ----- |
 | 17    0023 | LBSR        | RELATIVE     |   9   |   3   | ----- |
 | 18    0024 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 19    0025 | DAA         | INHERENT     |   2   |   1   | -aa0a |
 | 1A    0026 | ORCC        | IMMEDIATE    |   3   |   2   | ddddd |
 | 1B    0027 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 1C    0028 | ANDCC       | IMMEDIATE    |   3   |   2   | ddddd |
 | 1D    0029 | SEX         | INHERENT     |   2   |   1   | -aa0- |
 | 1E    0030 | EXG         | Immediate    |   8   |   2   | ccccc |
 | 1F    0031 | TFR         | Immediate    |   7   |   2   | ccccc |
 | 20    0032 | BRA         | RELATIVE     |   3   |   2   | ----- |
 | 21    0033 | BRN         | RELATIVE     |   3   |   2   | ----- |
 | 22    0034 | BHI         | RELATIVE     |   3   |   2   | ----- |
 | 23    0035 | BLS         | RELATIVE     |   3   |   2   | ----- |
 | 24    0036 | BHS/BCC     | RELATIVE     |   3   |   2   | ----- |
 | 25    0037 | BLO/BCS     | RELATIVE     |   3   |   2   | ----- |
 | 26    0038 | BNE         | RELATIVE     |   3   |   2   | ----- |
 | 27    0039 | BEQ         | RELATIVE     |   3   |   2   | ----- |
 | 28    0040 | BVC         | RELATIVE     |   3   |   2   | ----- |
 | 29    0041 | BVS         | RELATIVE     |   3   |   2   | ----- |
 | 2A    0042 | BPL         | RELATIVE     |   3   |   2   | ----- |
 | 2B    0043 | BMI         | RELATIVE     |   3   |   2   | ----- |
 | 2C    0044 | BGE         | RELATIVE     |   3   |   2   | ----- |
 | 2D    0045 | BLT         | RELATIVE     |   3   |   2   | ----- |
 | 2E    0046 | BGT         | RELATIVE     |   3   |   2   | ----- |
 | 2F    0047 | BLE         | RELATIVE     |   3   |   2   | ----- |
 | 30    0048 | LEAX        | INDEXED      |   4   |   2   | --a-- |
 | 31    0049 | LEAY        | INDEXED      |   4   |   2   | --a-- |
 | 32    0050 | LEAS        | INDEXED      |   4   |   2   | ----- |
 | 33    0051 | LEAU        | INDEXED      |   4   |   2   | ----- |
 | 34    0052 | PSHS        | Immediate    |   5   |   2   | ----- |
 | 35    0053 | PULS        | Immediate    |   5   |   2   | ccccc |
 | 36    0054 | PSHU        | Immediate    |   5   |   2   | ----- |
 | 37    0055 | PULU        | Immediate    |   5   |   2   | ccccc |
 | 38    0056 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 39    0057 | RTS         | INHERENT     |   5   |   1   | ----- |
 | 3A    0058 | ABX         | INHERENT     |   3   |   1   | ----- |
 | 3B    0059 | RTI         | INHERENT     | 6/15  |   1   | ----- |
 | 3C    0060 | CWAI        | Immediate    |  21   |   2   | ddddd |
 | 3D    0061 | MUL         | INHERENT     |  11   |   1   | --a-a |
 | 3E    0062 | RESET*      | INHERENT     |   *   |   1   | ***** |
 | 3F    0063 | SWI         | INHERENT     |  19   |   1   | ----- |
 | 40    0064 | NEGA        | INHERENT     |   2   |   1   | uaaaa |
 | 41    0065 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 42    0066 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 43    0067 | COMA        | INHERENT     |   2   |   1   | -aa01 |
 | 44    0068 | LSRA        | INHERENT     |   2   |   1   | -0a-s |
 | 45    0069 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 46    0070 | RORA        | INHERENT     |   2   |   1   | -aa-s |
 | 47    0071 | ASRA        | INHERENT     |   2   |   1   | uaa-s |
 | 48    0072 | LSLA/ASLA   | INHERENT     |   2   |   1   | naaas |
 | 49    0073 | ROLA        | INHERENT     |   2   |   1   | -aaas |
 | 4A    0074 | DECA        | INHERENT     |   2   |   1   | -aaa- |
 | 4B    0075 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 4C    0076 | INCA        | INHERENT     |   2   |   1   | -aaa- |
 | 4D    0077 | TSTA        | INHERENT     |   2   |   1   | -aa0- |
 | 4E    0078 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 4F    0079 | CLRA        | INHERENT     |   2   |   1   | -0100 |
 | 50    0080 | NEGB        | INHERENT     |   2   |   1   | uaaaa |
 | 51    0081 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 52    0082 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 53    0083 | COMB        | INHERENT     |   2   |   1   | -aa01 |
 | 54    0084 | LSRB        | INHERENT     |   2   |   1   | -0a-s |
 | 55    0085 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 56    0086 | RORB        | INHERENT     |   2   |   1   | -aa-s |
 | 57    0087 | ASRB        | INHERENT     |   2   |   1   | uaa-s |
 | 58    0088 | LSLB/ASLB   | INHERENT     |   2   |   1   | naaas |
 | 59    0089 | ROLB        | INHERENT     |   2   |   1   | -aaas |
 | 5A    0090 | DECB        | INHERENT     |   2   |   1   | -aaa- |
 | 5B    0091 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 5C    0092 | INCB        | INHERENT     |   2   |   1   | -aaa- |
 | 5D    0093 | TSTB        | INHERENT     |   2   |   1   | -aa0- |
 | 5E    0094 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 5F    0095 | CLRB        | INHERENT     |   2   |   1   | -0100 |
 | 60    0096 | NEG         | INDEXED      |   6   |   2   | uaaaa |
 | 61    0097 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 62    0098 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 63    0099 | COM         | INDEXED      |   6   |   2   | -aa01 |
 | 64    0100 | LSR         | INDEXED      |   6   |   2   | -0a-s |
 | 65    0101 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 66    0102 | ROR         | INDEXED      |   6   |   2   | -aa-s |
 | 67    0103 | ASR         | INDEXED      |   6   |   2   | uaa-s |
 | 68    0104 | LSL/ASL     | INDEXED      |   6   |   2   | naaas |
 | 69    0105 | ROL         | INDEXED      |   6   |   2   | -aaas |
 | 6A    0106 | DEC         | INDEXED      |   6   |   2   | -aaa- |
 | 6B    0107 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 6C    0108 | INC         | INDEXED      |   6   |   2   | -aaa- |
 | 6D    0109 | TST         | INDEXED      |   6   |   2   | -aa0- |
 | 6E    0110 | JMP         | INDEXED      |   3   |   2   | ----- |
 | 6F    0111 | CLR         | INDEXED      |   6   |   2   | -0100 |
 | 70    0112 | NEG         | EXTENDED     |   7   |   3   | uaaaa |
 | 71    0113 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 72    0114 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 73    0115 | COM         | EXTENDED     |   7   |   3   | -aa01 |
 | 74    0116 | LSR         | EXTENDED     |   7   |   3   | -0a-s |
 | 75    0117 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 76    0118 | ROR         | EXTENDED     |   7   |   3   | -aa-s |
 | 77    0119 | ASR         | EXTENDED     |   7   |   3   | uaa-s |
 | 78    0120 | LSL/ASL     | EXTENDED     |   7   |   3   | naaas |
 | 79    0121 | ROL         | EXTENDED     |   7   |   3   | -aaas |
 | 7A    0122 | DEC         | EXTENDED     |   7   |   3   | -aaa- |
 | 7B    0123 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 7C    0124 | INC         | EXTENDED     |   7   |   3   | -aaa- |
 | 7D    0125 | TST         | EXTENDED     |   7   |   3   | -aa0- |
 | 7E    0126 | JMP         | EXTENDED     |   3   |   3   | ----- |
 | 7F    0127 | CLR         | EXTENDED     |   7   |   3   | -0100 |
 | 80    0128 | SUBA        | IMMEDIATE    |   2   |   2   | uaaaa |
 | 81    0129 | CMPA        | IMMEDIATE    |   2   |   2   | uaaaa |
 | 82    0130 | SBCA        | IMMEDIATE    |   2   |   2   | uaaaa |
 | 83    0131 | SUBD        | IMMEDIATE    |   4   |   3   | -aaaa |
 | 84    0132 | ANDA        | IMMEDIATE    |   2   |   2   | -aa0- |
 | 85    0133 | BITA        | IMMEDIATE    |   2   |   2   | -aa0- |
 | 86    0134 | LDA         | IMMEDIATE    |   2   |   2   | -aa0- |
 | 87    0135 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 88    0136 | EORA        | IMMEDIATE    |   2   |   2   | -aa0- |
 | 89    0137 | ADCA        | IMMEDIATE    |   2   |   2   | aaaaa |
 | 8A    0138 | ORA         | IMMEDIATE    |   2   |   2   | -aa0- |
 | 8B    0139 | ADDA        | IMMEDIATE    |   2   |   2   | aaaaa |
 | 8C    0140 | CMPX        | IMMEDIATE    |   4   |   3   | -aaaa |
 | 8D    0141 | BSR         | RELATIVE     |   7   |   2   | ----- |
 | 8E    0142 | LDX         | IMMEDIATE    |   3   |   3   | -aa0- |
 | 8F    0143 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | 90    0144 | SUBA        | DIRECT       |   4   |   2   | uaaaa |
 | 91    0145 | CMPA        | DIRECT       |   4   |   2   | uaaaa |
 | 92    0146 | SBCA        | DIRECT       |   4   |   2   | uaaaa |
 | 93    0147 | SUBD        | DIRECT       |   6   |   2   | -aaaa |
 | 94    0148 | ANDA        | DIRECT       |   4   |   2   | -aa0- |
 | 95    0149 | BITA        | DIRECT       |   4   |   2   | -aa0- |
 | 96    0150 | LDA         | DIRECT       |   4   |   2   | -aa0- |
 | 97    0151 | STA         | DIRECT       |   4   |   2   | -aa0- |
 | 98    0152 | EORA        | DIRECT       |   4   |   2   | -aa0- |
 | 99    0153 | ADCA        | DIRECT       |   4   |   2   | aaaaa |
 | 9A    0154 | ORA         | DIRECT       |   4   |   2   | -aa0- |
 | 9B    0155 | ADDA        | DIRECT       |   4   |   2   | aaaaa |
 | 9C    0156 | CMPX        | DIRECT       |   6   |   2   | -aaaa |
 | 9D    0157 | JSR         | DIRECT       |   7   |   2   | ----- |
 | 9E    0158 | LDX         | DIRECT       |   5   |   2   | -aa0- |
 | 9F    0159 | STX         | DIRECT       |   5   |   2   | -aa0- |
 | A0    0160 | SUBA        | INDEXED      |   4   |   2   | uaaaa |
 | A1    0161 | CMPA        | INDEXED      |   4   |   2   | uaaaa |
 | A2    0162 | SBCA        | INDEXED      |   4   |   2   | uaaaa |
 | A3    0163 | SUBD        | INDEXED      |   6   |   2   | -aaaa |
 | A4    0164 | ANDA        | INDEXED      |   4   |   2   | -aa0- |
 | A5    0165 | BITA        | INDEXED      |   4   |   2   | -aa0- |
 | A6    0166 | LDA         | INDEXED      |   4   |   2   | -aa0- |
 | A7    0167 | STA         | INDEXED      |   4   |   2   | -aa0- |
 | A8    0168 | EORA        | INDEXED      |   4   |   2   | -aa0- |
 | A9    0169 | ADCA        | INDEXED      |   4   |   2   | aaaaa |
 | AA    0170 | ORA         | INDEXED      |   4   |   2   | -aa0- |
 | AB    0171 | ADDA        | INDEXED      |   4   |   2   | aaaaa |
 | AC    0172 | CMPX        | INDEXED      |   6   |   2   | -aaaa |
 | AD    0173 | JSR         | INDEXED      |   7   |   2   | ----- |
 | AE    0174 | LDX         | INDEXED      |   5   |   2   | -aa0- |
 | AF    0175 | STX         | INDEXED      |   5   |   2   | -aa0- |
 | B0    0176 | SUBA        | EXTENDED     |   5   |   3   | uaaaa |
 | B1    0177 | CMPA        | EXTENDED     |   5   |   3   | uaaaa |
 | B2    0178 | SBCA        | EXTENDED     |   5   |   3   | uaaaa |
 | B3    0179 | SUBD        | EXTENDED     |   7   |   3   | -aaaa |
 | B4    0180 | ANDA        | EXTENDED     |   5   |   3   | -aa0- |
 | B5    0181 | BITA        | EXTENDED     |   5   |   3   | -aa0- |
 | B6    0182 | LDA         | EXTENDED     |   5   |   3   | -aa0- |
 | B7    0183 | STA         | EXTENDED     |   5   |   3   | -aa0- |
 | B8    0184 | EORA        | EXTENDED     |   5   |   3   | -aa0- |
 | B9    0185 | ADCA        | EXTENDED     |   5   |   3   | aaaaa |
 | BA    0186 | ORA         | EXTENDED     |   5   |   3   | -aa0- |
 | BB    0187 | ADDA        | EXTENDED     |   5   |   3   | aaaaa |
 | BC    0188 | CMPX        | EXTENDED     |   7   |   3   | -aaaa |
 | BD    0189 | JSR         | EXTENDED     |   8   |   3   | ----- |
 | BE    0190 | LDX         | EXTENDED     |   6   |   3   | -aa0- |
 | BF    0191 | STX         | EXTENDED     |   6   |   3   | -aa0- |
 | C0    0192 | SUBB        | IMMEDIATE    |   2   |   2   | uaaaa |
 | C1    0193 | CMPB        | IMMEDIATE    |   2   |   2   | uaaaa |
 | C2    0194 | SBCB        | IMMEDIATE    |   2   |   2   | uaaaa |
 | C3    0195 | ADDD        | IMMEDIATE    |   4   |   3   | -aaaa |
 | C4    0196 | ANDB        | IMMEDIATE    |   2   |   2   | -aa0- |
 | C5    0197 | BITB        | IMMEDIATE    |   2   |   2   | -aa0- |
 | C6    0198 | LDB         | IMMEDIATE    |   2   |   2   | -aa0- |
 | C7    0199 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | C8    0200 | EORB        | IMMEDIATE    |   2   |   2   | -aa0- |
 | C9    0201 | ADCB        | IMMEDIATE    |   2   |   2   | aaaaa |
 | CA    0202 | ORB         | IMMEDIATE    |   2   |   2   | -aa0- |
 | CB    0203 | ADDB        | IMMEDIATE    |   2   |   2   | aaaaa |
 | CC    0204 | LDD         | IMMEDIATE    |   3   |   3   | -aa0- |
 | CD    0205 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | CE    0206 | LDU         | IMMEDIATE    |   3   |   3   | -aa0- |
 | CF    0207 | ILLEGAL     | ILLEGAL      |   1   |   1   | uuuuu |
 | D0    0208 | SUBB        | DIRECT       |   4   |   2   | uaaaa |
 | D1    0209 | CMPB        | DIRECT       |   4   |   2   | uaaaa |
 | D2    0210 | SBCB        | DIRECT       |   4   |   2   | uaaaa |
 | D3    0211 | ADDD        | DIRECT       |   6   |   2   | -aaaa |
 | D4    0212 | ANDB        | DIRECT       |   4   |   2   | -aa0- |
 | D5    0213 | BITB        | DIRECT       |   4   |   2   | -aa0- |
 | D6    0214 | LDB         | DIRECT       |   4   |   2   | -aa0- |
 | D7    0215 | STB         | DIRECT       |   4   |   2   | -aa0- |
 | D8    0216 | EORB        | DIRECT       |   4   |   2   | -aa0- |
 | D9    0217 | ADCB        | DIRECT       |   4   |   2   | aaaaa |
 | DA    0218 | ORB         | DIRECT       |   4   |   2   | -aa0- |
 | DB    0219 | ADDB        | DIRECT       |   4   |   2   | aaaaa |
 | DC    0220 | LDD         | DIRECT       |   5   |   2   | -aa0- |
 | DD    0221 | STD         | DIRECT       |   5   |   2   | -aa0- |
 | DE    0222 | LDU         | DIRECT       |   5   |   2   | -aa0- |
 | DF    0223 | STU         | DIRECT       |   5   |   2   | -aa0- |
 | E0    0224 | SUBB        | INDEXED      |   4   |   2   | uaaaa |
 | E1    0225 | CMPB        | INDEXED      |   4   |   2   | uaaaa |
 | E2    0226 | SBCB        | INDEXED      |   4   |   2   | uaaaa |
 | E3    0227 | ADDD        | INDEXED      |   6   |   2   | -aaaa |
 | E4    0228 | ANDB        | INDEXED      |   4   |   2   | -aa0- |
 | E5    0229 | BITB        | INDEXED      |   4   |   2   | -aa0- |
 | E6    0230 | LDB         | INDEXED      |   4   |   2   | -aa0- |
 | E7    0231 | STB         | INDEXED      |   4   |   2   | -aa0- |
 | E8    0232 | EORB        | INDEXED      |   4   |   2   | -aa0- |
 | E9    0233 | ADCB        | INDEXED      |   4   |   2   | aaaaa |
 | EA    0234 | ORB         | INDEXED      |   4   |   2   | -aa0- |
 | EB    0235 | ADDB        | INDEXED      |   4   |   2   | aaaaa |
 | EC    0236 | LDD         | INDEXED      |   5   |   2   | -aa0- |
 | ED    0237 | STD         | INDEXED      |   5   |   2   | -aa0- |
 | EE    0238 | LDU         | INDEXED      |   5   |   2   | -aa0- |
 | EF    0239 | STU         | INDEXED      |   5   |   2   | -aa0- |
 | F0    0240 | SUBB        | EXTENDED     |   5   |   3   | uaaaa |
 | F1    0241 | CMPB        | EXTENDED     |   5   |   3   | uaaaa |
 | F2    0242 | SBCB        | EXTENDED     |   5   |   3   | uaaaa |
 | F3    0243 | ADDD        | EXTENDED     |   7   |   3   | -aaaa |
 | F4    0244 | ANDB        | EXTENDED     |   5   |   3   | -aa0- |
 | F5    0245 | BITB        | EXTENDED     |   5   |   3   | -aa0- |
 | F6    0246 | LDB         | EXTENDED     |   5   |   3   | -aa0- |
 | F7    0247 | STB         | EXTENDED     |   5   |   3   | -aa0- |
 | F8    0248 | EORB        | EXTENDED     |   5   |   3   | -aa0- |
 | F9    0249 | ADCB        | EXTENDED     |   5   |   3   | aaaaa |
 | FA    0250 | ORB         | EXTENDED     |   5   |   3   | -aa0- |
 | FB    0251 | ADDB        | EXTENDED     |   5   |   3   | aaaaa |
 | FC    0252 | LDD         | EXTENDED     |   6   |   3   | -aa0- |
 | FD    0253 | STD         | EXTENDED     |   6   |   3   | -aa0- |
 | FE    0254 | LDU         | EXTENDED     |   6   |   3   | -aa0- |
 | FF    0255 | STU         | EXTENDED     |   6   |   3   | -aa0- |
 +------------+-------------+--------------+-------+-------+-------+

 +-----------------------------------------------------------------+
 |                       Page 1 Instructions^                      |
 +------------+-------------+--------------+---------------+-------+
 | Opcode     |             | Addressing   |               |       |
 | Hex   Dec  | Instruction | Mode         | Cycles  Bytes | HNZVC |
 +------------+-------------+--------------+-------+-------+-------+
 | 1021  4129 | LBRN        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1022  4130 | LBHI        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1023  4131 | LBLS        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1024  4132 | LBHS/LBCC   | RELATIVE     | 5(6)  |   4   | ----- |
 | 1025  4133 | LBLO/LBCS   | RELATIVE     | 5(6)  |   4   | ----- |
 | 1026  4134 | LBNE        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1027  4135 | LBEQ        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1028  4136 | LBVC        | RELATIVE     | 5(6)  |   4   | ----- |
 | 1029  4137 | LBVS        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102A  4138 | LBPL        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102B  4139 | LBMI        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102C  4140 | LBGE        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102D  4141 | LBLT        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102E  4142 | LBGT        | RELATIVE     | 5(6)  |   4   | ----- |
 | 102F  4143 | LBLE        | RELATIVE     | 5(6)  |   4   | ----- |
 | 103F  4159 | SWI2        | INHERENT     |  20   |   2   | ----- |
 | 1083  4227 | CMPD        | IMMEDIATE    |   5   |   4   | -aaaa |
 | 108C  4236 | CMPY        | IMMEDIATE    |   5   |   4   | -aaaa |
 | 108E  4238 | LDY         | IMMEDIATE    |   4   |   4   | -aa0- |
 | 1093  4243 | CMPD        | DIRECT       |   7   |   3   | -aaaa |
 | 109C  4252 | CMPY        | DIRECT       |   7   |   3   | -aaaa |
 | 109E  4254 | LDY         | DIRECT       |   6   |   3   | -aa0- |
 | 109F  4255 | STY         | DIRECT       |   6   |   3   | -aa0- |
 | 10A3  4259 | CMPD        | INDEXED      |   7   |   3   | -aaaa |
 | 10AC  4268 | CMPY        | INDEXED      |   7   |   3   | -aaaa |
 | 10AE  4270 | LDY         | INDEXED      |   6   |   3   | -aa0- |
 | 10AF  4271 | STY         | INDEXED      |   6   |   3   | -aa0- |
 | 10B3  4275 | CMPD        | EXTENDED     |   8   |   4   | -aaaa |
 | 10BC  4284 | CMPY        | EXTENDED     |   8   |   4   | -aaaa |
 | 10BE  4286 | LDY         | EXTENDED     |   7   |   4   | -aa0- |
 | 10BF  4287 | STY         | EXTENDED     |   7   |   4   | -aa0- |
 | 10CE  4302 | LDS         | IMMEDIATE    |   4   |   4   | -aa0- |
 | 10DE  4318 | LDS         | DIRECT       |   6   |   3   | -aa0- |
 | 10DF  4319 | STS         | DIRECT       |   6   |   3   | -aa0- |
 | 10EE  4334 | LDS         | INDEXED      |   6   |   3   | -aa0- |
 | 10EF  4335 | STS         | INDEXED      |   6   |   3   | -aa0- |
 | 10FE  4350 | LDS         | EXTENDED     |   7   |   4   | -aa0- |
 | 10FF  4351 | STS         | EXTENDED     |   7   |   4   | -aa0- |
 +------------+-------------+--------------+-------+-------+-------+

 +-----------------------------------------------------------------+
 |                       Page 2 Instructions^                      |
 +------------+-------------+--------------+---------------+-------+
 | Opcode     |             | Addressing   |               |       |
 | Hex   Dec  | Instruction | Mode         | Cycles  Bytes | HNZVC |
 +------------+-------------+--------------+-------+-------+-------+
 | 113F  4415 | SWI3        | INHERENT     |  20   |   2   | ----- |
 | 1183  4483 | CMPU        | IMMEDIATE    |   5   |   4   | -aaaa |
 | 118C  4492 | CMPS        | IMMEDIATE    |   5   |   4   | -aaaa |
 | 1193  4499 | CMPU        | DIRECT       |   7   |   3   | -aaaa |
 | 119C  4508 | CMPS        | DIRECT       |   7   |   3   | -aaaa |
 | 11A3  4515 | CMPU        | INDEXED      |   7   |   3   | -aaaa |
 | 11AC  4524 | CMPS        | INDEXED      |   7   |   3   | -aaaa |
 | 11B3  4531 | CMPU        | EXTENDED     |   8   |   4   | -aaaa |
 | 11BC  4540 | CMPS        | EXTENDED     |   8   |   4   | -aaaa |
 +------------+-------------+--------------+-------+-------+-------+"""


DONT_USE_ORIGIN_ACCESS_MODE = ("NEG")

instr_info_keys = INSTRUCTION_INFO.keys()


def get_instr_info(mnemonic, instruction):
    for instr_info_key, instr_info in INSTRUCTION_INFO.items():
        if mnemonic == instr_info_key:
            return instr_info_key, instr_info

    for instr_info_key, instr_info in INSTRUCTION_INFO.items():
        if not instr_info_key.startswith(instruction):
            continue

        try:
            source_forms = instr_info['source form']
        except KeyError:
            continue

        if mnemonic in source_forms:
            return instr_info_key, instr_info

    for instr_info_key, instr_info in INSTRUCTION_INFO.items():
        if instr_info_key.startswith(instruction):
            print "Use %s for %s (%s)" % (instr_info_key, mnemonic, instruction)
            return instr_info_key, instr_info

    test_mnemonic = mnemonic[1:]
    for instr_info_key, instr_info in INSTRUCTION_INFO.items():
        if instr_info_key == test_mnemonic:
            print "Use %s for %s (%s)" % (instr_info_key, mnemonic, instruction)
            return instr_info_key, instr_info

    return None, None


opcodes = []
categoriesed_opcodes = {}
for line in txt.splitlines():
    sections = line.split("|")
    if len(sections) != 8:
        continue
    sections = [s.strip() for s in sections if s.strip()]
    # ~ print sections
    raw_hex, raw_dec = sections[0].split(" ", 1)
    opcode = int(raw_hex, 16)
    op_dec = int(raw_dec)
    # ~ print hex(opcode), op_dec
    if not opcode == op_dec:
        print "ERROR!"

    mnemonic = sections[1]

    if mnemonic == "ILLEGAL":
        illegal.append(opcode)
        continue

#     if not mnemonic.startswith("LD"):continue
#     if not mnemonic.startswith("AND"):continue
#     if not mnemonic.startswith("BIT"):continue

    try:
        category_id, desc = OpDescriptions[mnemonic]
    except KeyError:
        # ~ print "***", mnemonic
        if not "/" in mnemonic:
            category_id = 8 # other
            desc = ""
        else:
            m1, m2 = mnemonic.split("/")
            desc_info1 = OpDescriptions[m1]
            desc_info2 = OpDescriptions[m2]
            # ~ print desc_info1
            # ~ print desc_info2
            if desc_info1 == desc_info2:
                category_id, desc = desc_info1
            else:
                category_id = desc_info1[0]
                desc = "%s / %s" % (desc_info1[1], desc_info2[1])


    operant = None
    instruction = mnemonic
    if instruction in CHANGE_INSTRUCTIONS:
        instruction = CHANGE_INSTRUCTIONS[instruction]
    for instr in INSTRUCTIONS:
        if mnemonic == instr:
            break

        if mnemonic.startswith(instr):
            instruction = instr
            operant_test = mnemonic[len(instruction):]
#             print " **** ", mnemonic, instruction, operant_test

            if operant_test in OPERANTS:
                operant = operant_test
            break

    instr_info_key, instr_info = get_instr_info(mnemonic, instruction)
    if instr_info is None:
        if instruction in CHANGED_INSTRUCTIONS:
            instr_info_key = instruction
            instr_info = INSTRUCTION_INFO[instruction]
        else:
            instr_info_key = OTHER_INSTRUCTIONS
            print "no INSTRUCTION_INFO found for %s" % repr(instruction)
            instr_info = INSTRUCTION_INFO.setdefault(OTHER_INSTRUCTIONS, {})
    elif not (instr_info_key.startswith(instruction) or instruction.endswith(instr_info_key)):
        print "ERROR:", instr_info_key
        pprint.pprint(instr_info)
        print "%r - $%x - %r - %s" % (instr_info_key, opcode, instruction, mnemonic)
        raise AssertionError

    instr_info["short_desc"] = desc
    raw_cycles = sections[3]
    try:
        cycles = int(raw_cycles)
    except ValueError, err:
        try:
            cycles = int(raw_cycles[0])
        except ValueError, err:
            print "Error: %s" % err
            print line
            cycles = -1
        else:
            print "Use sycles %i from %r" % (cycles, raw_cycles)

    bytes = int(sections[4])

    opcode_data = {
        "opcode": opcode,
        "category": category_id,
        "instruction": instruction,
        "mnemonic": mnemonic,
        "operant": operant,
        "addr_mode": ADDR_MODES[sections[2].upper()],
        "cycles": cycles,
        "bytes": bytes,
        "HNZVC": sections[5],
        "instr_info_key": instr_info_key,
    }
#     print "-"*79
#     pprint.pprint(opcode_data)
#     pprint.pprint(instr_info)
#     print "-"*7
    opcodes.append(opcode_data)
    categoriesed_opcodes.setdefault(category_id, []).append(opcode_data)


# sys.exit()


ADDR_MODES2 = dict(zip(ADDR_MODES.values(), ADDR_MODES.keys()))


for key, data in sorted(INSTRUCTION_INFO.items()):
    if key == OTHER_INSTRUCTIONS:
        continue

    try:
        addr_modes = data["addressing mode"]
    except KeyError, err:
        print "WARNING: no %s for %s" % (err, key)
        pprint.pprint(data)

    addr_mode_ids = []
    for addr_mode in addr_modes.split(" "):
        addr_mode = addr_mode.upper()
        try:
            addr_mode_ids.append(ADDR_MODES[addr_mode])
        except KeyError, err:
            print "ERROR: unknown addr. mode: %s from: %s" % (err, repr(addr_modes))
            print "data:",
            pprint.pprint(data)
            continue

    for opcode in opcodes:
#         print "***"
#         pprint.pprint(opcode)
        if opcode["instr_info_key"] != key:
            continue
        if not opcode["addr_mode"] in addr_mode_ids:
            print "ERROR: addr mode missmatch: $%x - IDs: %s" % (
                opcode["opcode"], repr(addr_mode_ids)
            ),
            if opcode["mnemonic"] in DONT_USE_ORIGIN_ACCESS_MODE:
                print " - Skip, ok."
            else:
                print
                print "data:",
                pprint.pprint(data)
                print "opcode:",
                pprint.pprint(opcode)
                raise AssertionError

    del(data["addressing mode"])


def pformat(item):
    txt = pprint.pformat(item, indent=4, width=80)
    txt = "\n  ".join(txt.split(" ", 1))
    return txt

class Tee(object):
    def __init__(self, filepath, origin_out):
        self.filepath = filepath
        self.origin_out = origin_out
        self.f = file(filepath, "w")

    def write(self, *args):
        txt = " ".join(args)
        self.origin_out.write(txt)
        self.f.write(txt)

    def close(self):
        self.f.close()
        sys.stdout = self.origin_out


sys.stdout = Tee("MC6809_data_raw.py", sys.stdout)


print '"""%s"""' % __doc__
print
print "OP_CATEGORIES = ", pformat(categories)
print
for id, txt in sorted(ADDR_MODES2.items()):
    print "%s=%s" % (txt, id)
print
print "ADDRES_MODE_DICT = {"
for id, txt in sorted(ADDR_MODES2.items()):
    print '    %s: "%s",' % (txt, txt)
print "}"
print
print '# operants:'
print 'X = "X"'
print 'Y = "Y"'
print 'U = "U"'
print 'S = "S"'
print 'A = "A"'
print 'B = "B"'
print 'D = "D"'
print 'CC = "CC"'
print
print 'OPERANT_DICT = {'
print '    X: "X (16 bit index register)",'
print '    Y: "Y (16 bit index register)",'
print '    U: "U (16 bit user stack pointer)",'
print '    S: "S (16 bit system stack pointer)",'
print '    A: "A (8 bit accumulator)",'
print '    B: "B (8 bit accumulator)",'
print '    D: "D (16 bit concatenated register A + B)",'
print '    CC: "CC (8 bit condition code register bits)",'
print '}'
print
print '# illegal opcode:'
print 'ILLEGAL_OPS = (%s)' % ",".join([hex(i) for i in illegal])
print
print '# other instructions'
print 'OTHER_INSTRUCTIONS = "OTHER_INSTRUCTIONS"'
print

print
print "# instruction info keys:"
for key in sorted(INSTRUCTION_INFO.keys()):
    print '%s="%s"' % (key, key)
print


print "INSTRUCTION_INFO = {"
for key, data in sorted(INSTRUCTION_INFO.items()):
    print '    %s: {' % key
    print " %s" % pprint.pformat(data, indent=8).strip("{}")
    print '    },'
print "}"
print


processed_opcodes = []
print
print "OP_DATA = ("
for category_id, category in categories.items():
    print
    print "    #### %s" % category
    print
    for opcode in categoriesed_opcodes[category_id]:
#         print pprint.pformat(opcode, indent=8)
        code = opcode["opcode"]
        assert code not in processed_opcodes, repr(opcode)
        processed_opcodes.append(code)

        print '    {'
        print '        "opcode": 0x%x, "instruction": "%s", "mnemonic": "%s",' % (
            opcode["opcode"], opcode["instruction"], opcode["mnemonic"]
        )
        print '        "addr_mode": %s, "operant": %s,' % (
            opcode["addr_mode"], opcode["operant"]
        )
        print '        "cycles": %i, "bytes": %i, "HNZVC": "%s",' % (
            opcode["cycles"], opcode["bytes"], opcode["HNZVC"]
        )
        print '        "category": %i, "instr_info_key": %s,' % (
            category_id, opcode["instr_info_key"]
        )
        print '    },'
print ")"

sys.stdout.close()

print "%i opcodes saved." % len(processed_opcodes)