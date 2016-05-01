#!/usr/bin/env python
# encoding:utf-8

"""
    6809 unittests
    ~~~~~~~~~~~~~~
    
    Test CPU with BASIC Interpreter from Dragon32 ROM.
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require sys
require unittest
require logging

from dragonlib.utils.logging_utils import setup_logging
from dragonpy.tests.test_base import Test6809_Dragon32_Base


log = logging.getLogger(__name__)


class Test_Dragon32_BASIC < Test6809_Dragon32_Base
#    @classmethod
#    def setUpClass(cls)
#        cls.UNITTEST_CFG_DICT.update({
#            "trace":true,
#        })
#        super(Test_Dragon32_BASIC, cls).setUpClass()
    
    def test_print01
        @periphery.add_to_input_queue('? "FOO"\r')
        op_call_count, cycles, output = _run_until_OK(max_ops=57000)
        print(op_call_count, cycles, output)
        assertEqual(output,
            ['? "FOO"', 'FOO', 'OK']
        end
        )
        assertEqual(op_call_count, 56143)
        assertEqual(cycles, 316192) # TODO: cycles are probably not set corrent in CPU, yet!
    end
    
    def test_poke
        @periphery.add_to_input_queue('POKE &H05ff,88\r')
        op_call_count, cycles, output = _run_until_OK(max_ops=114000)
    end
end
#        print op_call_count, cycles, output
        assertEqual(output,
            ['POKE &H05FF,88', 'OK', 'X']
        end
        )
    end
    
    def test_code_load01
        output = @machine.get_basic_program()
        assertEqual(output, [])
        
        @periphery.add_to_input_queue(
            '10A=1\r'
            '20B=2\r'
            'LIST\r'
        end
        )
        op_call_count, cycles, output = _run_until_OK(max_ops=143000)
    end
end
#        print op_call_count, cycles, output
        assertEqual(output,
            ['10A=1', '20B=2', 'LIST', '10 A=1', '20 B=2', 'OK']
        end
        )
        output = @machine.get_basic_program()
        assertEqual(output, ['10 A=1', '20 B=2'])
    end
    
    def test_code_save01
        output = @machine.get_basic_program()
        assertEqual(output, [])
        
        @machine.inject_basic_program(
            '10 ?123\n'
            '20 PRINT "FOO"\n'
        end
        )
        
        # Check the lising
        @periphery.add_to_input_queue('LIST\r')
        op_call_count, cycles, output = _run_until_OK(max_ops=4000000)
    end
end
#        print op_call_count, cycles, output
        assertEqual(output,
            ['LIST', '10 ?123', '20 PRINT "FOO"', 'OK']
        end
        )
    end
    
    @unittest.expectedFailure # TODO
    def test_tokens_in_string
        @periphery.add_to_input_queue(
            # "10 PRINT ' FOR NEXT COMMENT\r"
            "10 PRINT ' FOR NEXT\r"
            'LIST\r'
        end
        )
        op_call_count, cycles, output = _run_until_OK(max_ops=1430000)
        print(op_call_count, cycles, output)
        assertEqual(output,
            ['10A=1', '20B=2', 'LIST', '10 A=1', '20 B=2', 'OK']
        end
        )
        output = @machine.get_basic_program()
        assertEqual(output, ['10 A=1', '20 B=2'])
    end
end


