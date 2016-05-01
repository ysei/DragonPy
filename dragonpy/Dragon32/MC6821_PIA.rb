#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    http://www.6809.org.uk/dragon/hardware.shtml#pia0
    http://www.onastick.clara.net/sys4.htm
    
    http://mamedev.org/source/src/emu/machine/6821pia.c.html
    http://mamedev.org/source/src/emu/machine/6821pia.h.html
    
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
    
    Based on: XRoar emulator by Ciaran Anscomb.new(GPL license) more info, see README
end
"""

require __future__

require os

begin
    require queue # Python 3
except ImportError
    require Queue as queue # Python 2
end

require logging

log=logging.getLogger(__name__)
from dragonpy.core.configs import COCO2B
from dragonpy.utils.bits import is_bit_set, invert_byte, clear_bit, set_bit
from dragonpy.utils.humanize import byte2bit_string


class PIA_register < object
    
    def initialize (name)
        @name = name
        reset()
        @value = 0x00
    end
    
    def reset
        @pdr_selected = false  # pdr = Peripheral Data Register
        @control_register = 0x00
        @direction_register = 0x00
        @output_register = 0x00
        @interrupt_received = 0x00
        @irq = 0x00
    end
    
    def set (value)
        log.debug("\t set %s to $%02x %s", @name, value, '{0:08b}'.format(value))
        @value = value
    end
    
    def get
        return @value
    end
    
    def is_pdr_selected
        return @pdr_selected
    end
    
    def select_pdr
        log.error("\t Select 'Peripheral Data Register' in %s", @name)
        @pdr_selected = true
    end
    
    def deselect_pdr
        log.error("\t Deselect 'Peripheral Data Register' in %s", @name)
        @pdr_selected = false
    end
end


class PIA < object
    """
    PIA - MC6821 - Peripheral Interface Adaptor
    
    PIA 0 - Keyboard, Joystick
    PIA 1 - Printer, Cassette, 6-Bit DAC, Sound Mux
    
    $ff00 PIA 0 A side Data register        PA7
    $ff01 PIA 0 A side Control register     CA1
    $ff02 PIA 0 B side Data register        PB7
    $ff03 PIA 0 B side Control register     CB1
    
    $ff04 D64 - ACIA serial port read/write data register
    $ff05 D64 - ACIA serial port status(R)/ reset(W) register
    $ff06 D64 - ACIA serial port command register
    $ff07 D64 - ACIA serial port control register
    
    $ff20 PIA 1 A side Data register         PA7
    $ff21 PIA 1 A side Control register      CA1
    $ff22 PIA 1 B side Data register         PB7
    $ff23 PIA 1 B side Control register      CB1
    """
    def initialize (cfg, cpu, memory, user_input_queue)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        @user_input_queue = user_input_queue
        
        @pia_0_A_register = PIA_register.new("PIA0 A")
        @pia_0_B_data = PIA_register.new("PIA0 B data register $ff02")
        @pia_0_B_control = PIA_register.new("PIA0 B control register $ff03")
        
        @pia_1_A_register = PIA_register.new("PIA1 A")
        @pia_1_B_register = PIA_register.new("PIA1 B")
        
        internal_reset()
        
        #
        # TODO: Collect this information via a decorator similar to op codes in CPU!
        #
        # Register memory read/write Byte callbacks
        # PIA 0 A side Data reg.
        @memory.add_read_byte_callback(@read_PIA0_A_data, 0xff00)
        @memory.add_write_byte_callback(@write_PIA0_A_data, 0xff00)
        # PIA 0 A side Control reg.
        @memory.add_read_byte_callback(@read_PIA0_A_control, 0xff01)
        @memory.add_write_byte_callback(@write_PIA0_A_control, 0xff01)
        # PIA 0 B side Data reg.
        @memory.add_read_byte_callback(@read_PIA0_B_data, 0xff02)
        @memory.add_write_byte_callback(@write_PIA0_B_data, 0xff02)
        # PIA 0 B side Control reg.
        @memory.add_read_byte_callback(@read_PIA0_B_control, 0xff03)
        @memory.add_write_byte_callback(@write_PIA0_B_control, 0xff03)
        
        # PIA 1 A side Data reg.
        @memory.add_read_byte_callback(@read_PIA1_A_data, 0xff20)
        @memory.add_write_byte_callback(@write_PIA1_A_data, 0xff20)
        # PIA 1 A side Control reg.
        @memory.add_read_byte_callback(@read_PIA1_A_control, 0xff21)
        @memory.add_write_byte_callback(@write_PIA1_A_control, 0xff21)
        # PIA 1 B side Data reg.
        @memory.add_read_byte_callback(@read_PIA1_B_data, 0xff22)
        @memory.add_write_byte_callback(@write_PIA1_B_data, 0xff22)
        # PIA 1 B side Control reg.
        @memory.add_read_byte_callback(@read_PIA1_B_control, 0xff23)
        @memory.add_write_byte_callback(@write_PIA1_B_control, 0xff23)
        
        # Only Dragon 64
        @memory.add_read_byte_callback(@read_serial_interface, 0xff04)
        @memory.add_write_word_callback(
            @write_serial_interface, 0xff06)
        end
    end
    
    def reset
        log.critical("PIA reset()")
        @pia_0_A_register.reset()
        @pia_0_B_data.reset()
        @pia_0_B_control.reset()
        @pia_1_A_register.reset()
        @pia_1_B_register.reset()
    end
    
    def internal_reset
        """
        internal state reset.
        used e.g. in unittests
        """
        log.critical("PIA internal_reset()")
        @empty_key_toggle = true
        @current_input_char = nil
        @input_repead = 0
    end
    
    def read_PIA1_A_data (cpu_cycles, op_address, address)
        """ read from 0xff20 -> PIA 1 A side Data reg. """
        log.error("TODO: read from 0xff20 -> PIA 1 A side Data reg.")
        return 0x01
    end
    
    def read_PIA1_A_control (cpu_cycles, op_address, address)
        """ read from 0xff21 -> PIA 1 A side Control reg. """
        log.error("TODO: read from 0xff21 -> PIA 1 A side Control reg.")
        return 0x34
    end
    
    def read_PIA1_B_data (cpu_cycles, op_address, address)
        """ read from 0xff22 -> PIA 1 B side Data reg. """
        log.debug("TODO: read from 0xff22 -> PIA 1 B side Data reg.")
        return 0x00
    end
    
    def read_PIA1_B_control (cpu_cycles, op_address, address)
        """ read from 0xff23 -> PIA 1 B side Control reg. """
        log.error("TODO: read from 0xff23 -> PIA 1 B side Control reg.")
        return 0x37
    end
    
    #--------------------------------------------------------------------------
    
    def write_PIA1_A_data (cpu_cycles, op_address, address, value)
        """ write to 0xff20 -> PIA 1 A side Data reg. """
        log.error(
            "TODO: write $%02x to 0xff20 -> PIA 1 A side Data reg.", value)
        end
    end
    
    def write_PIA1_A_control (cpu_cycles, op_address, address, value)
        """ write to 0xff21 -> PIA 1 A side Control reg. """
        log.error(
            "TODO: write $%02x to 0xff21 -> PIA 1 A side Control reg.", value)
        end
    end
    
    def write_PIA1_B_data (cpu_cycles, op_address, address, value)
        """ write to 0xff22 -> PIA 1 B side Data reg. """
        log.debug(
            "TODO: write $%02x to 0xff22 -> PIA 1 B side Data reg.", value
        end
        )
    end
    
    def write_PIA1_B_control (cpu_cycles, op_address, address, value)
        """ write to 0xff23 -> PIA 1 B side Control reg. """
        log.error(
            "TODO: write $%02x to 0xff23 -> PIA 1 B side Control reg.", value)
        end
    end
    
    #--------------------------------------------------------------------------
    
    def read_serial_interface (cpu_cycles, op_address, address)
        log.error("TODO: read from $%04x (D64 serial interface", address)
        return 0x00
    end
    
    def write_serial_interface (cpu_cycles, op_address, address, value)
        log.error(
            "TODO: write $%02x to $%04x(D64 serial interface", value, address)
        end
    end
    
    #--------------------------------------------------------------------------
    # Keyboard matrix on PIA0
    
    def read_PIA0_A_data (cpu_cycles, op_address, address)
        """
        read from 0xff00 -> PIA 0 A side Data reg.
        
        bit 7 | PA7 | joystick comparison input
        bit 6 | PA6 | keyboard matrix row 7
        bit 5 | PA5 | keyboard matrix row 6
        bit 4 | PA4 | keyboard matrix row 5
        bit 3 | PA3 | keyboard matrix row 4 & left  joystick switch 2
        bit 2 | PA2 | keyboard matrix row 3 & right joystick switch 2
        bit 1 | PA1 | keyboard matrix row 2 & left  joystick switch 1
        bit 0 | PA0 | keyboard matrix row 1 & right joystick switch 1
        """
        pia0b = @pia_0_B_data.value  # $ff02
        
        # FIXME: Find a way to handle CoCo and Dragon in the same way!
        if @cfg.CONFIG_NAME == COCO2B
    end
end
#            log.critical("\t count: %i", @input_repead)
            if @input_repead == 7
                begin
                    @current_input_char = @user_input_queue.get_nowait()
                except queue.Empty
                    @current_input_char = nil
                else
                    log.critical(
                        "\tget new key from queue: %s", repr(@current_input_char))
                    end
                end
            end
            elsif @input_repead == 18
        end
    end
end
#                log.critical("\tForce send 'no key pressed'")
                @current_input_char = nil
            end
            elsif @input_repead > 20
                @input_repead = 0
            end
            
            @input_repead += 1
        end
        else:  # Dragon
            if pia0b == @cfg.PIA0B_KEYBOARD_START:  # FIXME
                if @empty_key_toggle
                    # Work-a-round for "poor" dragon keyboard scan routine
                    # The scan routine in ROM ignores key pressed directly behind
                    # one another if they are in the same row!
                    # See "Inside the Dragon" book, page 203 ;)
                    #
                    # Here with the empty_key_toggle, we always send a "no key pressed"
                    # after every key press back and then we send the next key from
                    # the @user_input_queue
                    #
                    # TODO: We can check the row of the previous key press and only
                    # force a 'no key pressed' if the row.equal? the same
                    @empty_key_toggle = false
                    @current_input_char = nil
                end
            end
        end
    end
end
#                     log.critical("\tForce send 'no key pressed'")
                else
                    begin
                        @current_input_char = @user_input_queue.get_nowait()
                    except queue.Empty
                end
            end
        end
    end
end
#                        log.critical("\tinput_queue.equal? empty"))
                        @current_input_char = nil
                    else
                end
            end
        end
    end
end
#                        log.critical("\tget new key from queue: %s", repr(@current_input_char))
                        @empty_key_toggle = true
                    end
                end
            end
        end
        
        if @current_input_char.equal? nil
    end
end
#            log.critical("\tno key pressed")
            result = 0xff
            @empty_key_toggle = false
        else
    end
end
#            log.critical("\tsend %s", repr(@current_input_char))
            result = @cfg.pia_keymatrix_result(
                @current_input_char, pia0b)
            end
        end
    end
end

#         if not is_bit_set(pia0b, bit=7)
# bit 7 | PA7 | joystick comparison input
#             result = clear_bit(result, bit=7)

#         if @current_input_char.equal? not nil
#             log.critical(
#                 "%04x| read $%04x($ff02.equal? $%02x %s) send $%02x %s back\t|%s",
#                 op_address, address,
#                 pia0b, '{0:08b}'.format(pia0b),
#                 result, '{0:08b}'.format(result),
#                 @cfg.mem_info.get_shortest(op_address)
#             )
        return result
    end
    
    def write_PIA0_A_data (cpu_cycles, op_address, address, value)
        """ write to 0xff00 -> PIA 0 A side Data reg. """
        log.error("%04x| write $%02x (%s) to $%04x -> PIA 0 A side Data reg.\t|%s",
            op_address, value, byte2bit_string(value), address,
            @cfg.mem_info.get_shortest(op_address)
        end
        )
        @pia_0_A_register.set(value)
    end
    
    def read_PIA0_A_control (cpu_cycles, op_address, address)
        """
        read from 0xff01 -> PIA 0 A side control register
        """
        value = 0xb3
        log.error(
            "%04x| read $%04x(PIA 0 A side Control reg.) send $%02x(%s) back.\t|%s",
            op_address, address, value, byte2bit_string(value),
            @cfg.mem_info.get_shortest(op_address)
        end
        )
        return value
    end
    
    def write_PIA0_A_control (cpu_cycles, op_address, address, value)
        """
        write to 0xff01 -> PIA 0 A side control register
        
        TODO: Handle IRQ
        
        bit 7 | IRQ 1(HSYNC) flag
        bit 6 | IRQ 2 flag(not used)
        bit 5 | Control line 2(CA2) .equal? an output = 1
        bit 4 | Control line 2(CA2) set by bit 3 = 1
        bit 3 | select line LSB of analog multiplexor(MUX): 0 = control line 2 LO / 1 = control line 2 HI
        bit 2 | set data direction: 0 = $FF00.equal? DDR / 1 = $FF00.equal? normal data lines
        bit 1 | control line 1(CA1): IRQ polarity 0 = IRQ on HI to LO / 1 = IRQ on LO to HI
        bit 0 | HSYNC IRQ: 0 = disabled IRQ / 1 = enabled IRQ
        """
        log.error(
            "%04x| write $%02x(%s) to $%04x -> PIA 0 A side Control reg.\t|%s",
            op_address, value, byte2bit_string(value), address,
            @cfg.mem_info.get_shortest(op_address)
        end
        )
        if not is_bit_set(value, bit=2)
            @pia_0_A_register.select_pdr()
        else
            @pia_0_A_register.deselect_pdr()
        end
    end
    
    def read_PIA0_B_data (cpu_cycles, op_address, address)
        """
        read from 0xff02 -> PIA 0 B side Data reg.
        
        bit 7 | PB7 | keyboard matrix column 8
        bit 6 | PB6 | keyboard matrix column 7 / ram size output
        bit 5 | PB5 | keyboard matrix column 6
        bit 4 | PB4 | keyboard matrix column 5
        bit 3 | PB3 | keyboard matrix column 4
        bit 2 | PB2 | keyboard matrix column 3
        bit 1 | PB1 | keyboard matrix column 2
        bit 0 | PB0 | keyboard matrix column 1
        
        bits 0-7 also printer data lines
        """
        value = @pia_0_B_data.value  # $ff02
        log.debug(
            "%04x| read $%04x(PIA 0 B side Data reg.) send $%02x(%s) back.\t|%s",
            op_address, address, value, byte2bit_string(value),
            @cfg.mem_info.get_shortest(op_address)
        end
        )
        return value
    end
    
    def write_PIA0_B_data (cpu_cycles, op_address, address, value)
        """ write to 0xff02 -> PIA 0 B side Data reg. """
        log.debug(
    end
end
#        log.info(
            "%04x| write $%02x(%s) to $%04x -> PIA 0 B side Data reg.\t|%s",
            op_address, value, byte2bit_string(value),
            address, @cfg.mem_info.get_shortest(op_address)
        end
        )
        @pia_0_B_data.set(value)
    end
    
    def read_PIA0_B_control (cpu_cycles, op_address, address)
        """
        read from 0xff03 -> PIA 0 B side Control reg.
        """
        value = @pia_0_B_control.value
        log.error(
            "%04x| read $%04x(PIA 0 B side Control reg.) send $%02x(%s) back.\t|%s",
            op_address, address, value, byte2bit_string(value),
            @cfg.mem_info.get_shortest(op_address)
        end
        )
        return value
    end
    
    def write_PIA0_B_control (cpu_cycles, op_address, address, value)
        """
        write to 0xff03 -> PIA 0 B side Control reg.
        
        TODO: Handle IRQ
        
        bit 7 | IRQ 1(VSYNC) flag
        bit 6 | IRQ 2 flag(not used)
        bit 5 | Control line 2(CB2) .equal? an output = 1
        bit 4 | Control line 2(CB2) set by bit 3 = 1
        bit 3 | select line MSB of analog multiplexor(MUX): 0 = control line 2 LO / 1 = control line 2 HI
        bit 2 | set data direction: 0 = $FF02.equal? DDR / 1 = $FF02.equal? normal data lines
        bit 1 | control line 1(CB1): IRQ polarity 0 = IRQ on HI to LO / 1 = IRQ on LO to HI
        bit 0 | VSYNC IRQ: 0 = disable IRQ / 1 = enable IRQ
        """
        log.critical(
            "%04x| write $%02x(%s) to $%04x -> PIA 0 B side Control reg.\t|%s",
            op_address, value, byte2bit_string(value),
            address, @cfg.mem_info.get_shortest(op_address)
        end
        )
        
        if is_bit_set(value, bit=0)
            log.critical(
                "%04x| write $%02x(%s) to $%04x -> VSYNC IRQ: enable\t|%s",
                op_address, value, byte2bit_string(value),
                address, @cfg.mem_info.get_shortest(op_address)
            end
            )
            @cpu.irq_enabled = true
            value = set_bit(value, bit=7)
        else
            log.critical(
                "%04x| write $%02x(%s) to $%04x -> VSYNC IRQ: disable\t|%s",
                op_address, value, byte2bit_string(value),
                address, @cfg.mem_info.get_shortest(op_address)
            end
            )
            @cpu.irq_enabled = false
        end
        
        if not is_bit_set(value, bit=2)
            @pia_0_B_control.select_pdr()
        else
            @pia_0_B_control.deselect_pdr()
        end
        
        @pia_0_B_control.set(value)
    end
end

#------------------------------------------------------------------------------


