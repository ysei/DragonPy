#!/usr/bin/env python
# encoding:utf-8

"""
    6809 unittests
    ~~~~~~~~~~~~~~

    Test CPU with some small Assembler programs

    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
"""

from decimal import Decimal
import binascii
import logging
import sys
import unittest

from tests.test_base import TextTestRunner2, BaseStackTestCase


log = logging.getLogger("DragonPy")


class Test6809_Program(BaseStackTestCase):
    def _crc16(self, data):
        """
        origin code by Johann E. Klasek, j AT klasek at
        """
        data_address = 0x1000 # position of the test data
        self.cpu.memory.load(data_address, data) # write test data into RAM
        self.cpu.user_stack_pointer.set(data_address) # start address of data
        self.cpu.index_x.set(len(data)) # number of bytes

        self.cpu_test_run(start=0x0100, end=None, mem=[
            #                                         .ORG  $100
            #                                   CRCH: EQU   $10
            #                                   CRCL: EQU   $21
            #                                  CRC16:
            #                                     BL:
            0xA8, 0xC0, #                             EORA  ,u+        ; fetch byte and XOR into CRC high byte
            0x10, 0x8E, 0x00, 0x08, #                 LDY   #8         ; rotate loop counter
            0x58, #                               RL: ASLB             ; shift CRC left, first low
            0x49, #                                   ROLA             ; and than high byte
            0x24, 0x04, #                             BCC   cl         ; Justify or ...
            0x88, 0x10, #                             EORA  #CRCH      ; CRC=CRC XOR polynomic, high
            0xC8, 0x21, #                             EORB  #CRCL      ; and low byte
            0x31, 0x3F, #                         CL: LEAY  -1,y       ; shift loop (8 bits)
            0x26, 0xF4, #                             BNE   rl
            0x30, 0x1F, #                             LEAX  -1,x       ; byte loop
            0x26, 0xEA, #                             BNE   bl
        ])
        crc16 = self.cpu.accu_d.get()
        return crc16

    def test_crc16_01(self):
        crc16 = self._crc16("Z")
        self.assertEqualHex(crc16, 0xfbbf)

    def test_crc16_02(self):
        crc16 = self._crc16("DragonPy works?!?")
        self.assertEqualHex(crc16, 0xA30D)

    def _crc32(self, data):
        """
        Calculate a ZIP 32-bit CRC from data in memory.
        Origin code by Johann E. Klasek, j AT klasek at
        """
        data_address = 0x1000 # position of the test data
        self.cpu.memory.load(data_address, data)  # write test data into RAM
        self.cpu.index_x.set(data_address + len(data)) # end address
        addr_hi, addr_lo = divmod(data_address, 0x100) # start address

        self.cpu_test_run(start=0x0100, end=None, mem=[
            #                              0100|           .ORG  $100
            0x10, 0xCE, 0x40, 0x00, #      0100|           LDS   #$4000
            #                              0104|    CRCHH: EQU   $ED
            #                              0104|    CRCHL: EQU   $B8
            #                              0104|    CRCLH: EQU   $83
            #                              0104|    CRCLL: EQU   $20
            #                              0104| CRCINITH: EQU   $FFFF
            #                              0104| CRCINITL: EQU   $FFFF
            #                              0104|                            ; CRC 32 bit in DP (4 bytes)
            #                              0104|      CRC: EQU   $80
            0xCE, addr_hi, addr_lo, #      0104|           LDU   #....      ; start address in u
            0x34, 0x10, #                  010C|           PSHS  x          ; end address +1 to TOS
            0xCC, 0xFF, 0xFF, #            010E|           LDD   #CRCINITL
            0xDD, 0x82, #                  0111|           STD   crc+2
            0x8E, 0xFF, 0xFF, #            0113|           LDX   #CRCINITH
            0x9F, 0x80, #                  0116|           STX   crc
            #                              0118|                            ; d/x contains the CRC
            #                              0118|       BL:
            0xE8, 0xC0, #                  0118|           EORB  ,u+        ; XOR with lowest byte
            0x10, 0x8E, 0x00, 0x08, #      011A|           LDY   #8         ; bit counter
            #                              011E|       RL:
            0x1E, 0x01, #                  011E|           EXG   d,x
            #                              0120|      RL1:
            0x44, #                        0120|           LSRA             ; shift CRC right, beginning with high word
            0x56, #                        0121|           RORB
            0x1E, 0x01, #                  0122|           EXG   d,x
            0x46, #                        0124|           RORA             ; low word
            0x56, #                        0125|           RORB
            0x24, 0x12, #                  0126|           BCC   cl
            #                              0128|                            ; CRC=CRC XOR polynomic
            0x88, 0x83, #                  0128|           EORA  #CRCLH     ; apply CRC polynomic low word
            0xC8, 0x20, #                  012A|           EORB  #CRCLL
            0x1E, 0x01, #                  012C|           EXG   d,x
            0x88, 0xED, #                  012E|           EORA  #CRCHH     ; apply CRC polynomic high word
            0xC8, 0xB8, #                  0130|           EORB  #CRCHL
            0x31, 0x3F, #                  0132|           LEAY  -1,y       ; bit count down
            0x26, 0xEA, #                  0134|           BNE   rl1
            0x1E, 0x01, #                  0136|           EXG   d,x        ; CRC: restore correct order
            0x27, 0x04, #                  0138|           BEQ   el         ; leave bit loop
            #                              013A|       CL:
            0x31, 0x3F, #                  013A|           LEAY  -1,y       ; bit count down
            0x26, 0xE0, #                  013C|           BNE   rl         ; bit loop
            #                              013E|       EL:
            0x11, 0xA3, 0xE4, #            013E|           CMPU  ,s         ; end address reached?
            0x26, 0xD5, #                  0141|           BNE   bl         ; byte loop
            0xDD, 0x82, #                  0143|           STD   crc+2      ; CRC low word
            0x9F, 0x80, #                  0145|           STX   crc        ; CRC high word
        ])
        d = self.cpu.accu_d.get()
        x = self.cpu.index_x.get()
        crc32 = x * 0x10000 + d
        return crc32 ^ 0xFFFFFFFF

    def _test_crc32(self, txt):
        crc32 = self._crc32(txt)
        excpected_crc32 = binascii.crc32(txt) & 0xffffffff
        hex1 = "$%08x" % crc32
        hex2 = "$%08x" % excpected_crc32
#        print
#        print "Test String: %s" % repr(txt)
#        print "\tpython..:", hex1
#        print "\tcrc32...:", hex2
        self.assertEqual(hex1, hex2)

    def test_crc32_01(self):
        self._test_crc32("a09") # $3617c6fe

    def test_crc32_02(self):
        self._test_crc32("DragonPy test!") # $570e3666

    def test_crc32_03(self):
        self._test_crc32("ZYXWVUTSRQPONMLKJIHGFEDBCA") # $99cdfdb2

    # following tests works too but takes some time to run:
#    def test_crc32_04(self):
#        self._test_crc32("DragonPy Integration testing...") # $728b1186
#    def test_crc32_05(self):
#        self._test_crc32("An Arbitrary String") # $6fbeaae7
#    def test_crc32_06(self):
#        self._test_crc32("ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789") # $749f0b1a

    def _division(self, dividend, divisor):
        assert isinstance(dividend, int)
        assert isinstance(divisor, int)
        assert 0x0 <= dividend <= 0x100000000
        assert 0x0 <= divisor <= 0x10000

        a = [dividend >> (i << 3) & 0xff for i in (3, 2, 1, 0)]
#         print "a:", [hex(i) for i in a]

        b = [divisor >> (i << 3) & 0xff for i in (1, 0)]
#         print "b:", [hex(i) for i in b]

        """
        orgigin code from Talbot System FIG Forth and modifyed by J.E. Klasek j+forth@klasek.at
        see:
        https://github.com/6809/sbc09/blob/master/examples/uslash.asm
        """
        self.cpu_test_run(start=0x0100, end=None, mem=[
            #                              0100|           .ORG  $100
            #                              0100|                            ; sample parameters on stack ...
            0xCC, a[2], a[3], #            0100|           LDD   #$....     ; dividend low word
            0x36, 0x06, #                  0103|           PSHU  d
            0xCC, a[0], a[1], #            0105|           LDD   #$....     ; dividend high word
            0x36, 0x06, #                  0108|           PSHU  d
            0xCC, b[0], b[1], #            010A|           LDD   #$....     ; divisor word
            0x36, 0x06, #                  010D|           PSHU  d
            0xEC, 0x42, #                  010F|   USLASH: LDD   2,u
            0xAE, 0x44, #                  0111|           LDX   4,u
            0xAF, 0x42, #                  0113|           STX   2,u
            0xED, 0x44, #                  0115|           STD   4,u
            0x68, 0x43, #                  0117|           ASL   3,u        ; initial shift of L word
            0x69, 0x42, #                  0119|           ROL   2,u
            0x8E, 0x00, 0x10, #            011B|           LDX   #$10
            0x69, 0x45, #                  011E|     USL1: ROL   5,u        ; shift H word
            0x69, 0x44, #                  0120|           ROL   4,u
            0xEC, 0x44, #                  0122|           LDD   4,u
            0xA3, 0xC4, #                  0124|           SUBD  ,u         ; does divisor fit?
            0x1C, 0xFE, #                  0126|           ANDCC #$FE       ; clc - clear carry flag
            0x2B, 0x04, #                  0128|           BMI   USL2
            0xED, 0x44, #                  012A|           STD   4,u        ; fits -> quotient = 1
            0x1A, 0x01, #                  012C|           ORCC  #$01       ; sec - Set Carry flag
            0x69, 0x43, #                  012E|     USL2: ROL   3,u        ; L word/quotient
            0x69, 0x42, #                  0130|           ROL   2,u
            0x30, 0x1F, #                  0132|           LEAX  -1,x
            0x26, 0xE8, #                  0134|           BNE   USL1
            0x33, 0x42, #                  0136|           LEAU  2,u
            0xAE, 0xC4, #                  0138|           LDX   ,u         ; quotient
            0xEC, 0x42, #                  013A|           LDD   2,u        ; remainder
        ])
        quotient = self.cpu.index_x.get()
        remainder = self.cpu.accu_d.get()
        return quotient, remainder

    def test_division(self):
        def test(dividend, divisor):
            """
            dividend / divisor = quotient
            """
            quotient, remainder = self._division(dividend, divisor)
#             print quotient, remainder

            a = Decimal(dividend)
            b = Decimal(divisor)
            expected_quotient = a // b
            expected_remainder = a % b

            first = "%i/%i=%i remainder: %i" % (dividend, divisor, quotient, remainder)
            second = "%i/%i=%i remainder: %i" % (dividend, divisor, expected_quotient, expected_remainder)
#             print first
            self.assertEqual(first, second)

        test(10, 5)
        test(10, 3)
        test(1000, 2000)
        test(0xffff, 0x80)
        test(0xfffff, 0x800)
        test(0xffffff, 0x8000)
        test(0xfffffff, 0x8000)
        test(1, 0x8000)

#         test(1, 0x8001) # Error: '1/32769=65534 remainder: 3' != '1/32769=0 remainder: 1'
#         test(1, 0x9000) # Error: '10/65535=65533 remainder: 7' != '10/65535=0 remainder: 10'
#         test(10, 0xffff) # Error: '10/65535=65533 remainder: 7' != '10/65535=0 remainder: 10'
#         test(0xfffffff, 0xffff) # Error: '268435455/65535=57342 remainder: 57341' != '268435455/65535=4096 remainder: 4095'



if __name__ == '__main__':
    log.setLevel(
#        1
#        10 # DEBUG
#         20 # INFO
#         30 # WARNING
#         40 # ERROR
        50 # CRITICAL/FATAL
    )
    log.addHandler(logging.StreamHandler())

    # XXX: Disable hacked XRoar trace
    import cpu6809; cpu6809.trace_file = None

    unittest.main(
        argv=(
            sys.argv[0],
#            "Test6809_Program.test_crc16_01",
#            "Test6809_Program.test_crc32_01",
#             "Test6809_Program.test_division",
        ),
        testRunner=TextTestRunner2,
#         verbosity=1,
        verbosity=2,
#         failfast=True,
    )
