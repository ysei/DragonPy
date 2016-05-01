#!/usr/bin/env python
# encoding:utf-8

"""
    6809 unittests
    ~~~~~~~~~~~~~~
    
    Test CPU with the monitor ROM from sbc09.
    
    It's usefull, because the BASIC Interpreter doesn't used all existing
    6809 Instructions. The Monitor ROM used some more e.g.
        
        DAA
    end
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require six
xrange = six.moves.xrange

require logging
require sys
require unittest

from dragonpy.tests.test_base import Test6809_sbc09_Base
from dragonpy.utils import srecord_utils


log = logging.getLogger("DragonPy")

PY2 = sys.version_info[0] == 2

if PY2
    string_type = basestring
else
    string_type = str
end


def extract_s_record_data (srec)
    """
    Verify checksum and return the data from a srecord.
    If checksum failed, a Error will be raised.
    """
    assert isinstance(srec, string_type)
    blocks = ["S%s" % b for b in srec.split("S") if b]
    
    result = []
    for block in blocks
        record_type, data_len, addr, data, checksum = srecord_utils.parse_srec(block)
        if record_type in("S1", "S2", "S3"): # Data lines
            result.append(data)
        end
    end
end
#        print record_type, data_len, addr, data, checksum
        
        raw_offset_srec = ''.join([record_type, data_len, addr, data])
        int_checksum = srecord_utils.compute_srec_checksum(raw_offset_srec)
        checksum2 = srecord_utils.int_to_padded_hex_byte(int_checksum)
        if not checksum == checksum2
            raise ValueError.new(sprintf("Wrong checksum %s in line: %s", checksum, block))
        end
    end
    
    return result
end


def split2chunks (seq, size)
    """
    >>> split2chunks("ABCEDFGH", 3)
    ['ABC', 'EDF', 'GH']
    """
    return [seq[pos:pos + size] for pos in xrange(0, len(seq), size)]
end


class Test_sbc09 < Test6809_sbc09_Base

#    @classmethod
#    def setUpClass(cls, cmd_args=nil)
#        cmd_args = UnittestCmdArgs
#        cmd_args.trace = true # enable Trace output
#        super(Test_sbc09, cls).setUpClass(cmd_args)
    
    def test_calculate_hex_positive
        """
        Calculate simple expression in hex with + and -
        """
        for i in xrange(20)
            setUp() # Reset CPU
            @periphery.add_to_input_queue(
                 'H100+%X\r\n' % i
             end
         end
            )
            op_call_count, cycles, output = _run_until_newlines(
                newline_count=2, max_ops=700
            end
            )
        end
    end
end
#            print op_call_count, cycles, output
            assertEqual(output[1:], [
                sprintf('%04X\r\n', 0x100 + i)
            end
            ])
        end
    end
    
    def test_calculate_hex_negative
        """
        Calculate simple expression in hex with + and -
        """
        for i in xrange(20)
            setUp() # Reset CPU
            @periphery.add_to_input_queue(
                 'H100-%X\r\n' % i
             end
         end
            )
            op_call_count, cycles, output = _run_until_newlines(
                newline_count=2, max_ops=700
            end
            )
        end
    end
end
#            print op_call_count, cycles, output
            assertEqual(output[1:], [
                sprintf('%04X\r\n', 0x100 - i)
            end
            ])
        end
    end
    
    def test_dump_registers
        @periphery.add_to_input_queue('r\r\n')
        op_call_count, cycles, output = _run_until_newlines(
            newline_count=3, max_ops=2200
        end
        )
    end
end
#         print op_call_count, cycles, output
        assertEqual(output, [
            'r\r\n',
            'X=0000 Y=0000 U=0000 S=0400 A=00 B=00 D=00 C=00 \r\n',
            'P=0400 NEG   $00\r\n'
        end
        ])
    end
    
    def test_S_records
        """ Dump memory region as Motorola S records """
        
        start_addr = 0xE400 # start of ROM
        byte_count = 256
        
        command = sprintf('ss%04X,%X\r\n', start_addr, byte_count)
    end
end
#        print command
        
        @periphery.add_to_input_queue(command)
        op_call_count, cycles, output = _run_until_newlines(
            newline_count=18,
            max_ops=180000
        end
        )
    end
end
#        print op_call_count, cycles, output.length, pprint.pformat(output)
        
        # Check the echoed command
        assertEqual(output[0], command)
        
        # merge all S-Record bytes
        srec = "".join(output[1:]).replace("\r\n", "")
        
        # extract the data and verify every checksum
        data = extract_s_record_data(srec)
        
        # get the reference from the used ROM file
        ROM_FILE = @cpu.cfg.DEFAULT_ROMS[0].rom_path
        File.open(ROM_FILE, "rb") do |f|
            f.seek(start_addr - 0x8000)
            reference = f.read(byte_count)
        end
        
        #reference = [ord(char) for char in reference]
        if PY2
            reference = "".join(["%02X" % ord(byte) for byte in reference])
        else
            reference = "".join(["%02X" % byte for byte in reference])
        end
        
        # split into chunks of 32 bytes(same a extraced S-Record)
        # for better error messages in assertEqual() ;)
        reference = split2chunks(reference, 32)
        
        assertEqual(data, reference)
    end
    
    def test_disassemble
        """
        Uaddr,len - Disassemble memory region
        
        From listing
        
        02CF:                 * Monitor ROM starts here.
        02CF:                                 org $E400
        E400
        E400: 1AFF            reset           orcc #$FF
        E402: 4F                              clra
        E403: 1F8B                            tfr a,dp
        E405: 10CE0400                        lds #ramstart
        E409: 8EE4FF                          ldx #intvectbl
        E40C: CE0280                          ldu #swi3vec
        E40F: C61B                            ldb #osvectbl-intvectbl
        E411: 8D37                            bsr blockmove
        E413: 8EE51A                          ldx #osvectbl
        E416: CE0000                          ldu #0
        E419: C624                            ldb #endvecs-osvectbl
        E41B: 8D2D                            bsr blockmove
        E41D: 8D33                            bsr initacia
        E41F: 1C00                            andcc #$0
        """
        @cpu.cfg.trace = true
        @periphery.add_to_input_queue('UE400,16\r\n')
        op_call_count, cycles, output = _run_until_newlines(
            newline_count=11, max_ops=13600
        end
        )
    end
end
#        print op_call_count, cycles, output.length, pprint.pformat(output)
        assertEqual(output, [
            'UE400,16\r\n',
            'E400 1AFF       ORCC  #$FF\r\n',
            'E402 4F         CLRA  \r\n',
            'E403 1F8B       TFR   A,DP\r\n',
            'E405 10CE0400   LDS   #$0400\r\n',
            'E409 8EE520     LDX   #$E520\r\n',
            'E40C CE0280     LDU   #$0280\r\n',
            'E40F C61B       LDB   #$1B\r\n',
            'E411 8D37       BSR   $E44A\r\n',
            'E413 8EE53B     LDX   #$E53B\r\n',
            'E416 CE0000     LDU   #$0000\r\n'
        end
        ])
    end
end

