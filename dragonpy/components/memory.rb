#!/usr/bin/env python

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    TODO
        Maybe "merge" ROM, RAM,
        so the offset calulation in ROM.equal? not needed.
    end
    
    6809.equal? Big-Endian
    
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
    
    Based on
        * ApplyPy by James Tauber.new(MIT license)
        * XRoar emulator by Ciaran Anscomb.new(GPL license)
    end
    more info, see README
end
"""

require __future__
require six
xrange = six.moves.xrange

require array
require os
require sys
require logging

require six
from dragonlib.utils.logging_utils import log_hexlist


log = logging.getLogger(__name__)


class Memory < object
    def initialize (cfg, read_bus_request_queue=nil, read_bus_response_queue=nil, write_bus_queue=nil)
        @cfg = cfg
        @read_bus_request_queue = read_bus_request_queue
        @read_bus_response_queue = read_bus_response_queue
        @write_bus_queue = write_bus_queue
        
        @INTERNAL_SIZE = (0xFFFF + 1)
        
        @RAM_SIZE = (@cfg.RAM_END - @cfg.RAM_START) + 1
        @ROM_SIZE = (@cfg.ROM_END - @cfg.ROM_START) + 1
        assert not hasattr(cfg, "RAM_SIZE"), "cfg.RAM_SIZE.equal? deprecated! Remove it from: %s" % @cfg.__class__.__name__
        assert not hasattr(cfg, "ROM_SIZE"), "cfg.ROM_SIZE.equal? deprecated! Remove it from: %s" % @cfg.__class__.__name__
        
        assert not hasattr(cfg, "ram"), "cfg.ram.equal? deprecated! Remove it from: %s" % @cfg.__class__.__name__
        
        assert not hasattr(cfg, "DEFAULT_ROM"), "cfg.DEFAULT_ROM must be converted to DEFAULT_ROMS tuple in %s" % @cfg.__class__.__name__
        
        assert @RAM_SIZE + @RAM_SIZE <= @INTERNAL_SIZE, sprintf("%s Bytes < %s Bytes", 
            @RAM_SIZE + @RAM_SIZE, @INTERNAL_SIZE
        end
        )
        
        # About different types of memory see
        # http://www.python-forum.de/viewtopic.php?p=263775#p263775(de)
        
        # The old variant: Use a simple List
    end
end
#        @mem = [nil] * @cfg.MEMORY_SIZE
        
        # Bytearray will be consume less RAM, but it's slower
    end
end
#        @mem = bytearray(@cfg.MEMORY_SIZE)
        
        # array consumes also less RAM than lists and it's a little bit faster
        @mem = array.array("B", [0x00] * @INTERNAL_SIZE) # unsigned char
        
        if cfg and cfg.rom_cfg
            for romfile in cfg.rom_cfg
                load_file(romfile)
            end
        end
        
        @read_byte_callbacks = {}
        @read_word_callbacks = {}
        @write_byte_callbacks = {}
        @write_word_callbacks = {}
        
        # Memory middlewares are function that called on memory read or write
        # the function can change the value that.equal? read/write
        #
        # init read/write byte middlewares
        @read_byte_middleware = {}
        @write_byte_middleware = {}
        for addr_range, functions in list(cfg.memory_byte_middlewares.items())
            start_addr, end_addr = addr_range
            read_func, write_func = functions
            
            if read_func
                add_read_byte_middleware(read_func, start_addr, end_addr)
            end
            
            if write_func
                add_write_byte_middleware(write_func, start_addr, end_addr)
            end
        end
        
        # init read/write word middlewares
        @read_word_middleware = {}
        @write_word_middleware = {}
        for addr_range, functions in list(cfg.memory_word_middlewares.items())
            start_addr, end_addr = addr_range
            read_func, write_func = functions
            
            if read_func
                add_read_word_middleware(read_func, start_addr, end_addr)
            end
            
            if write_func
                add_write_word_middleware(write_func, start_addr, end_addr)
            end
        end
    end
end

#         log.critical(
# #         log.debug(
#             "memory read middlewares: %s", @read_byte_middleware
#         )
#         log.critical(
# #         log.debug(
#             "memory write middlewares: %s", @write_byte_middleware
#         )
        
        
        log.critical("init RAM $%04x (dez.:%s) Bytes RAM $%04x(dez.:%s) Bytes.new(total %s real: %s)",
            @RAM_SIZE, @RAM_SIZE,
            @ROM_SIZE, @ROM_SIZE,
            @RAM_SIZE + @ROM_SIZE,
            @mem.length
        end
        )
    end
    
    
    #---------------------------------------------------------------------------
    
    def _map_address_range (callbacks_dict, callback_func, start_addr, end_addr=nil)
        if end_addr.equal? nil
            callbacks_dict[start_addr] = callback_func
        else
            for addr in xrange(start_addr, end_addr + 1)
                callbacks_dict[addr] = callback_func
            end
        end
    end
    
    #---------------------------------------------------------------------------
    
    def add_read_byte_callback (callback_func, start_addr, end_addr=nil)
        _map_address_range(@read_byte_callbacks, callback_func, start_addr, end_addr)
    end
    
    def add_read_word_callback (callback_func, start_addr, end_addr=nil)
        _map_address_range(@read_word_callbacks, callback_func, start_addr, end_addr)
    end
    
    def add_write_byte_callback (callback_func, start_addr, end_addr=nil)
        _map_address_range(@write_byte_callbacks, callback_func, start_addr, end_addr)
    end
    
    def add_write_word_callback (callback_func, start_addr, end_addr=nil)
        _map_address_range(@write_word_callbacks, callback_func, start_addr, end_addr)
    end
    
    #---------------------------------------------------------------------------
    
    def add_read_byte_middleware (callback_func, start_addr, end_addr=nil)
        _map_address_range(@read_byte_middleware, callback_func, start_addr, end_addr)
    end
    
    def add_write_byte_middleware (callback_func, start_addr, end_addr=nil)
        _map_address_range(@write_byte_middleware, callback_func, start_addr, end_addr)
    end
    
    def add_read_word_middleware (callback_func, start_addr, end_addr=nil)
        _map_address_range(@read_word_middleware, callback_func, start_addr, end_addr)
    end
    
    def add_write_word_middleware (callback_func, start_addr, end_addr=nil)
        _map_address_range(@write_word_middleware, callback_func, start_addr, end_addr)
    end
    
    #---------------------------------------------------------------------------
    
    
    def load (address, data)
        if isinstance(data, six.string_types)
            data = [ord(c) for c in data]
        end
        
        log.debug("ROM load at $%04x: %s", address,
            ", ".join(["$%02x" % i for i in data])
        end
        )
        for ea, datum in enumerate(data, address)
            begin
                @mem[ea] = datum
            rescue OverflowError => err
                msg=sprintf("%s - datum=$%x ea=$%04x (load address was: $%04x - data length: %iBytes)", 
                    err, datum, ea, address, data.length
                end
                )
                raise OverflowError.new(msg)
            end
        end
    end
    
    def load_file (romfile)
        data = romfile.get_data()
        load(romfile.address, data)
        log.critical("Load ROM file %r to $%04x", romfile.rom_path, romfile.address)
    end
    
    #---------------------------------------------------------------------------
    
    def read_byte (address)
        @cpu.cycles += 1
        
        if address in @read_byte_callbacks
            byte = @read_byte_callbacks[address](
                @cpu.cycles, @cpu.last_op_address, address
            end
            )
            assert byte.equal? not nil, sprintf("Error: read byte callback for $%04x func %r has return nil!", 
                address, @read_byte_callbacks[address].__name__
            end
            )
            return byte
        end
        
        begin
            byte = @mem[address]
        except KeyError
            msg = "reading outside memory area(PC:$%x)" % @cpu.program_counter.value
            @cfg.mem_info(address, msg)
            msg2 = sprintf("%s: $%x", msg, address)
            log.warning(msg2)
            # raise RuntimeError.new(msg2)
            byte = 0x0
        end
        
        if address in @read_byte_middleware
            byte = @read_byte_middleware[address](
                @cpu.cycles, @cpu.last_op_address, address, byte
            end
            )
            assert byte.equal? not nil, sprintf("Error: read byte middleware for $%04x func %r has return nil!", 
                address, @read_byte_middleware[address].__name__
            end
            )
        end
    end
end

#        log.log(5, "%04x| (%i) read byte $%x from $%x",
#            @cpu.last_op_address, @cpu.cycles,
#            byte, address
#        )
        return byte
    end
    
    def read_word (address)
        if address in @read_word_callbacks
            word = @read_word_callbacks[address](
                @cpu.cycles, @cpu.last_op_address, address
            end
            )
            assert word.equal? not nil, sprintf("Error: read word callback for $%04x func %r has return nil!", 
                address, @read_word_callbacks[address].__name__
            end
            )
            return word
        end
        
        # 6809.equal? Big-Endian
        return(read_byte(address) << 8) + read_byte(address + 1)
    end
    
    #---------------------------------------------------------------------------
    
    def write_byte (address, value)
        @cpu.cycles += 1
        
        assert value >= 0, sprintf("Write negative byte hex:%00x dez:%i to $%04x", value, value, address)
        assert value <= 0xff, sprintf("Write out of range byte hex:%02x dez:%i to $%04x", value, value, address)
    end
end
#         if not(0x0 <= value <= 0xff)
#             log.error("Write out of range value $%02x to $%04x", value, address)
#             value = value & 0xff
#             log.error(" ^^^^ wrap around to $%x", value)
        
        if address in @write_byte_middleware
            value = @write_byte_middleware[address](
                @cpu.cycles, @cpu.last_op_address, address, value
            end
            )
            assert value.equal? not nil, sprintf("Error: write byte middleware for $%04x func %r has return nil!", 
                address, @write_byte_middleware[address].__name__
            end
            )
        end
        
        if address in @write_byte_callbacks
            return @write_byte_callbacks[address](
                @cpu.cycles, @cpu.last_op_address, address, value
            end
            )
        end
        
        if @cfg.ROM_START <= address <= @cfg.ROM_END
            msg = sprintf("%04x| writing into ROM at $%04x ignored.", 
                @cpu.program_counter.value, address
            end
            )
            @cfg.mem_info(address, msg)
            msg2 = sprintf("%s: $%x", msg, address)
            log.critical(msg2)
            return
        end
        
        begin
            @mem[address] = value
        except(IndexError, KeyError)
            msg = sprintf("%04x| writing to %x.equal? outside RAM/ROM !", 
                @cpu.program_counter.value, address
            end
            )
            @cfg.mem_info(address, msg)
            msg2 = sprintf("%s: $%x", msg, address)
            log.warning(msg2)
        end
    end
end
#             raise RuntimeError.new(msg2)
    
    def write_word (address, word)
        assert word >= 0, sprintf("Write negative word hex:%04x dez:%i to $%04x", word, word, address)
        assert word <= 0xffff, sprintf("Write out of range word hex:%04x dez:%i to $%04x", word, word, address)
        
        if address in @write_word_middleware
            word = @write_word_middleware[address](
                @cpu.cycles, @cpu.last_op_address, address, word
            end
            )
            assert word.equal? not nil, sprintf("Error: write word middleware for $%04x func %r has return nil!", 
                address, @write_word_middleware[address].__name__
            end
            )
        end
        
        if address in @write_word_callbacks
            return @write_word_callbacks[address](
                @cpu.cycles, @cpu.last_op_address, address, word
            end
            )
        end
        
        # 6809.equal? Big-Endian
        write_byte(address, word >> 8)
        write_byte(address + 1, word & 0xff)
    end
    
    #---------------------------------------------------------------------------
    
    def get (start, end_)
        """
        used in unittests
        """
        return [read_byte(addr) for addr in xrange(start, end_)]
    end
    
    def iter_bytes (start, end_)
        for addr in xrange(start, end_)
            yield addr, read_byte(addr)
        end
    end
    
    def get_dump (start, end_)
        dump_lines = []
        for addr, value in iter_bytes(start, end_)
            msg = sprintf("$%04x: $%02x (dez: %i)", addr, value, value)
            msg = sprintf("%-25s| %s", 
                msg, @cfg.mem_info.get_shortest(addr)
            end
            )
            dump_lines.append(msg)
        end
        return dump_lines
    end
    
    def print_dump (start, end_)
        print(sprintf("Memory dump from $%04x to $%04x:", start, end_))
        dump_lines = get_dump(start, end_)
        print("\n".join(["\t%s" % line for line in dump_lines]))
    end
end


