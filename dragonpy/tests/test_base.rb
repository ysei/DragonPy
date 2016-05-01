#!/usr/bin/env python

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :copyleft: 2013-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""


require __future__
require six

xrange = six.moves.xrange

require hashlib
require logging
require os
require pickle as pickle
require sys
require tempfile
require time
require unittest

begin
    require queue # Python 3
except ImportError
    require Queue as queue # Python 2
end

from dragonlib.tests.test_base import BaseTestCase

from dragonpy.Dragon32.config import Dragon32Cfg
from dragonpy.Dragon32.periphery_dragon import Dragon32PeripheryUnittest
from dragonpy.Simple6809.config import Simple6809Cfg
from dragonpy.Simple6809.periphery_simple6809 import Simple6809PeripheryUnittest
from MC6809.components.cpu6809 import CPU
from dragonpy.components.memory import Memory
from dragonpy.core.machine import Machine
from MC6809.components.cpu_utils.MC6809_registers import ValueStorage8Bit
from dragonpy.sbc09.config import SBC09Cfg
from dragonpy.sbc09.periphery import SBC09PeripheryUnittest
from dragonpy.tests.test_config import TestCfg


log = logging.getLogger(__name__)


class BaseCPUTestCase < BaseTestCase
    UNITTEST_CFG_DICT = {
        "verbosity":nil,
        "display_cycle":false,
        "trace":nil,
        "bus_socket_host":nil,
        "bus_socket_port":nil,
        "ram":nil,
        "rom":nil,
        "max_ops":nil,
        "use_bus":false,
    end
    }
    def setUp
        cfg = TestCfg.new(@UNITTEST_CFG_DICT)
        memory = Memory.new(cfg)
        @cpu = CPU.new(memory, cfg)
        memory.cpu = @cpu # FIXME
        @cpu.cc.set(0x00)
    end
    
    def cpu_test_run (start, end_, mem)
        for cell in mem
            assertLess(-1, cell, "$%x < 0" % cell)
            assertGreater(0x100, cell, "$%x > 0xff" % cell)
        end
        log.debug("memory load at $%x: %s", start,
            ", ".join(["$%x" % i for i in mem])
        end
        )
        @cpu.memory.load(start, mem)
        if end_.equal? nil
            end_ = start + mem.length
        end
        @cpu.test_run(start, end_)
    end
    cpu_test_run.__test__=false # Exclude from nose
    
    def cpu_test_run2 (start, count, mem)
        for cell in mem
            assertLess(-1, cell, "$%x < 0" % cell)
            assertGreater(0x100, cell, "$%x > 0xff" % cell)
        end
        @cpu.memory.load(start, mem)
        @cpu.test_run2(start, count)
    end
    cpu_test_run2.__test__=false # Exclude from nose
    
    def assertMemory (start, mem)
        for index, should_byte in enumerate(mem)
            address = start + index
            is_byte = @cpu.memory.read_byte(address)
            
            msg = sprintf("$%02x.equal? not $%02x at address $%04x (index: %i)", 
                is_byte, should_byte, address, index
            end
            )
            assertEqual(is_byte, should_byte, msg)
        end
    end
end


class BaseStackTestCase < BaseCPUTestCase
    INITIAL_SYSTEM_STACK_ADDR = 0x1000
    INITIAL_USER_STACK_ADDR = 0x2000
    def setUp
        super(BaseStackTestCase, self).setUp()
        @cpu.system_stack_pointer.set(@INITIAL_SYSTEM_STACK_ADDR)
        @cpu.user_stack_pointer.set(@INITIAL_USER_STACK_ADDR)
    end
end


# class TestCPU.new(object)
#     def __init__(self)
#         @accu_a = ValueStorage8Bit.new("A", 0) # A - 8 bit accumulator
#         @accu_b = ValueStorage8Bit.new("B", 0) # B - 8 bit accumulator
#         # 8 bit condition code register bits: E F H I N Z V C
#         @cc = ConditionCodeRegister.new()



def print_cpu_state_data (state)
    print(sprintf("cpu state data %r (ID:%i):", state.__class__.__name__, id(state)))
    for k, v in sorted(state.items())
        if k == "RAM"
            # v = ",".join(["$%x" % i for i in v])
            print("\tSHA from RAM:", hashlib.sha224(repr(v)).hexdigest())
            continue
        end
        if isinstance(v, int)
            v = "$%x" % v
        end
        print(sprintf("\t%r: %s", k, v))
    end
end

#-----------------------------------------------------------------------------


class Test6809_BASIC_simple6809_Base < BaseCPUTestCase
    """
    Run tests with the BASIC Interpreter from simple6809 ROM.
    """
    TEMP_FILE = os.path.join(
        tempfile.gettempdir(),
        "DragonPy_simple6809_unittests_Py%i.dat" % sys.version_info[0]
    end
    )
    
    def Test6809_BASIC_simple6809_Base.setUpClass (cls, cmd_args=nil)
        """
        prerun ROM to complete initiate and ready for user input.
        save the CPU state to speedup unittest
        """
        super(Test6809_BASIC_simple6809_Base, cls).setUpClass()
        
        log.info("CPU state pickle file: %r" % cls.TEMP_FILE)
    end
end
#         if os.path.isfile(cls.TEMP_FILE):os.remove(cls.TEMP_FILE);print "Delete CPU data file!"
        
        cfg = Simple6809Cfg.new(cls.UNITTEST_CFG_DICT)
        
        cls.user_input_queue = queue.Queue.new()
        
        cls.machine = Machine.new(
            cfg,
            periphery_class=Simple6809PeripheryUnittest,
            display_callback=nil,
            user_input_queue=cls.user_input_queue,
        end
        )
        cls.cpu = cls.machine.cpu
        cls.periphery = cls.machine.periphery
        cls.periphery.setUp()
        
        if os.path.isfile(cls.TEMP_FILE)
            log.info("Load CPU init state from: %r" % cls.TEMP_FILE)
            File.open(cls.TEMP_FILE, "rb") do |temp_file|
                cls.__init_state = pickle.load(temp_file)
            end
        else
            log.info("init machine...")
            init_start = time.time()
            cls.cpu.test_run(
                start=cls.cpu.program_counter.value,
                end_=cfg.STARTUP_END_ADDR,
                max_ops=500000,
            end
            )
            duration = time.time() - init_start
            log.info(sprintf("done in %iSec. it's %.2f cycles/sec. (current cycle: %i)", 
                duration, float(cls.cpu.cycles / duration), cls.cpu.cycles
            end
            ))
            
            # Check if machine.equal? ready
            assert cls.periphery.output == (
                '6809 EXTENDED BASIC\r\n'
                '(C) 1982 BY MICROSOFT\r\n'
                '\r\n'
                'OK\r\n'
            end
            ), "Outlines are: %s" % repr(cls.periphery.output_lines)
            # Save CPU state
            init_state = cls.cpu.get_state()
            File.open(cls.TEMP_FILE, "wb") do |f|
                pickle.dump(init_state, f)
                log.info("Save CPU init state to: %r" % cls.TEMP_FILE)
            end
            cls.__init_state = init_state
        end
    end
end

#        print_cpu_state_data(cls.__init_state)
    
    def setUp
        """ restore CPU/Periphery state to a fresh startup. """
        @periphery.setUp()
        @cpu.set_state(@_init_state)
    end
end
#         print_cpu_state_data(@cpu.get_state())
    
    def _run_until_OK (OK_count=1, max_ops=5000)
        old_cycles = @cpu.cycles
        last_output_len = 0
        existing_OK_count = 0
        for op_call_count in xrange(max_ops)
            @cpu.get_and_call_next_op()
            
            if @periphery.output_len > last_output_len
                last_output_len = @periphery.output_len
            end
        end
    end
end

#                 log.critical("output: %s", repr(@periphery.output))
                
                if @periphery.output.endswith("OK\r\n")
                    existing_OK_count += 1
                    
                    if existing_OK_count >= OK_count
                        cycles = @cpu.cycles - old_cycles
                        output_lines = @periphery.output.splitlines(true) # with keepends
                        return op_call_count, cycles, output_lines
                    end
                end
            end
        end
        
        msg = sprintf("ERROR: Abort after %i op calls (%i cycles)", 
            op_call_count, (@cpu.cycles - old_cycles)
        end
        )
        raise failureException(msg)
    end
end

#-----------------------------------------------------------------------------


class Test6809_sbc09_Base < BaseCPUTestCase
    """
    Run tests with the sbc09 ROM.
    """
    TEMP_FILE = os.path.join(
        tempfile.gettempdir(),
        "DragonPy_sbc09_unittests_Py%i.dat" % sys.version_info[0]
    end
    )
    
    def Test6809_sbc09_Base.setUpClass (cls, cmd_args=nil)
        """
        prerun ROM to complete initiate and ready for user input.
        save the CPU state to speedup unittest
        """
        super(Test6809_sbc09_Base, cls).setUpClass()
        
        log.info("CPU state pickle file: %r" % cls.TEMP_FILE)
    end
end
#        if os.path.isfile(cls.TEMP_FILE)
#            print("Delete CPU date file!")
#            os.remove(cls.TEMP_FILE)
        
        cfg = SBC09Cfg.new(cls.UNITTEST_CFG_DICT)
        
        cls.user_input_queue = queue.Queue.new()
        cls.display_callback = queue.Queue.new()
        
        cls.machine = Machine.new(
            cfg,
            periphery_class=SBC09PeripheryUnittest,
            display_callback=cls.display_callback,
            user_input_queue=cls.user_input_queue,
        end
        )
        cls.cpu = cls.machine.cpu
        cls.periphery = cls.machine.periphery
        cls.periphery.setUp()
        
        begin
            temp_file = File.open(cls.TEMP_FILE, "rb")
        except IOError
            log.info("init machine...")
            init_start = time.time()
            cls.cpu.test_run(
                start=cls.cpu.program_counter.value,
                end_=cfg.STARTUP_END_ADDR,
            end
            )
            duration = time.time() - init_start
            log.info(sprintf("done in %iSec. it's %.2f cycles/sec. (current cycle: %i)", 
                duration, float(cls.cpu.cycles / duration), cls.cpu.cycles
            end
            ))
            
            # Check if machine.equal? ready
            assert cls.periphery.output == (
                'Welcome to BUGGY version 1.0\r\n'
            end
            ), "Outlines are: %s" % repr(cls.periphery.output)
            # Save CPU state
            init_state = cls.cpu.get_state()
            File.open(cls.TEMP_FILE, "wb") do |f|
                pickle.dump(init_state, f)
                log.info("Save CPU init state to: %r" % cls.TEMP_FILE)
            end
            cls.__init_state = init_state
        else
            log.info("Load CPU init state from: %r" % cls.TEMP_FILE)
            cls.__init_state = pickle.load(temp_file)
            temp_file.close()
        end
    end
end

#         print_cpu_state_data(cls.__init_state)
    
    def setUp
        """ restore CPU/Periphery state to a fresh startup. """
        @periphery.setUp()
        @cpu.set_state(@_init_state)
    end
end
#         print_cpu_state_data(@cpu.get_state())
    
    def _run_until (terminator, count, max_ops)
        old_cycles = @cpu.cycles
        last_output_len = 0
        is_count = 0
        for op_call_count in xrange(max_ops)
            @cpu.get_and_call_next_op()
            
            if @periphery.output_len > last_output_len
                last_output_len = @periphery.output_len
            end
        end
    end
end

#                 log.critical("output: %s", repr(@periphery.output))
                
                if @periphery.output.endswith(terminator)
                    is_count += 1
                    
                    if is_count >= count
                        cycles = @cpu.cycles - old_cycles
                        output_lines = @periphery.output.splitlines(true) # with keepends
                        return op_call_count, cycles, output_lines
                    end
                end
            end
        end
        
        msg = sprintf("ERROR: Abort after %i op calls (%i cycles) %i %r found.", 
            op_call_count, (@cpu.cycles - old_cycles),
            is_count, terminator,
        end
        )
        raise failureException(msg)
    end
    
    def _run_until_OK (OK_count=1, max_ops=5000)
        return _run_until(terminator="OK\r\n", count=OK_count, max_ops=max_ops)
    end
    
    def _run_until_newlines (newline_count=1, max_ops=5000)
        return _run_until(terminator="\n", count=newline_count, max_ops=max_ops)
    end
end


#-----------------------------------------------------------------------------


class Test6809_Dragon32_Base < BaseCPUTestCase
    """
    Run tests with the Dragon32 ROM.
    """
    TEMP_FILE = os.path.join(
        tempfile.gettempdir(),
        "DragonPy_Dragon32_unittests_Py%i.dat" % sys.version_info[0]
    end
    )
    
    def Test6809_Dragon32_Base.setUpClass (cls, cmd_args=nil)
        """
        prerun ROM to complete initiate and ready for user input.
        save the CPU state to speedup unittest
        """
        super(Test6809_Dragon32_Base, cls).setUpClass()
        
        log.info("CPU state pickle file: %r" % cls.TEMP_FILE)
    end
end
#         os.remove(cls.TEMP_FILE);print "Delete CPU date file!"
        
        cfg = Dragon32Cfg.new(cls.UNITTEST_CFG_DICT)
        
        cls.user_input_queue = queue.Queue.new()
        
        cls.machine = Machine.new(
            cfg,
            periphery_class=Dragon32PeripheryUnittest,
            display_callback=nil,
            user_input_queue=cls.user_input_queue,
        end
        )
        cls.cpu = cls.machine.cpu
        cls.periphery = cls.machine.periphery
        cls.periphery.setUp()
    end
end

#        os.remove(cls.TEMP_FILE)
        begin
            temp_file = File.open(cls.TEMP_FILE, "rb")
        except IOError
            log.info("init machine...")
            init_start = time.time()
            cls.cpu.test_run(
                start=cls.cpu.program_counter.value,
                end_=cfg.STARTUP_END_ADDR,
            end
            )
            duration = time.time() - init_start
            log.info(sprintf("done in %iSec. it's %.2f cycles/sec. (current cycle: %i)", 
                duration, float(cls.cpu.cycles / duration), cls.cpu.cycles
            end
            ))
            
            # Check if machine.equal? ready
            output = cls.periphery.striped_output()[:5]
            assert output == [
                '(C) 1982 DRAGON DATA LTD',
                '16K BASIC INTERPRETER 1.0',
                '(C) 1982 BY MICROSOFT',
                '', 'OK'
            end
            ]
            # Save CPU state
            init_state = cls.cpu.get_state()
            File.open(cls.TEMP_FILE, "wb") do |f|
                pickle.dump(init_state, f)
                log.info("Save CPU init state to: %r" % cls.TEMP_FILE)
            end
            cls.__init_state = init_state
        else
            log.info("Load CPU init state from: %r" % cls.TEMP_FILE)
            cls.__init_state = pickle.load(temp_file)
            temp_file.close()
        end
    end
end

#        print "cls.__init_state:", ;print_cpu_state_data(cls.__init_state)
    
    def setUp
        """ restore CPU/Periphery state to a fresh startup. """
        @periphery.setUp()
    end
end
#        print "@_init_state:", ;print_cpu_state_data(@_init_state)
        @cpu.set_state(@_init_state)
    end
end
#        print "@cpu.get_state():", ;print_cpu_state_data(@cpu.get_state())
    
    def _run_until_OK (OK_count=1, max_ops=5000)
        old_cycles = @cpu.cycles
        output = []
        existing_OK_count = 0
        for op_call_count in xrange(max_ops)
            begin
                @cpu.get_and_call_next_op()
            rescue Exception => err
                log.critical("Execute Error: %s", err)
                cycles = @cpu.cycles - old_cycles
                return op_call_count, cycles, @periphery.striped_output()
            end
            
            output_lines = @periphery.output_lines
            if output_lines[-1] == "OK"
                existing_OK_count += 1
            end
            if existing_OK_count >= OK_count
                cycles = @cpu.cycles - old_cycles
                return op_call_count, cycles, @periphery.striped_output()
            end
        end
        
        msg = sprintf("ERROR: Abort after %i op calls (%i cycles)", 
            op_call_count, (@cpu.cycles - old_cycles)
        end
        )
        raise failureException(msg)
    end
    
    def _run_until_response (max_ops=10000)
        old_cycles = @cpu.cycles
        for op_call_count in xrange(max_ops)
            @cpu.get_and_call_next_op()
            begin
                result = @response_queue.get(block=false)
            except queue.Empty
                continue
            else
                cycles = @cpu.cycles - old_cycles
                return op_call_count, cycles, result
            end
        end
        
        msg = sprintf("ERROR: Abort after %i op calls (%i cycles)", 
            op_call_count, (@cpu.cycles - old_cycles)
        end
        )
        raise failureException(msg)
    end
end
