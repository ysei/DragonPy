#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    http://www.6809.org.uk/dragon/hardware.shtml#sam
    
    $ffc0-ffdf    SAM.new(Synchronous Address Multiplexer) register bits - use
                      even address to clear, odd address to set
                  end
              end
          end
      end
  end
    $ffc0-ffc5    SAM VDG Mode registers V0-V2
    $ffc0/ffc1    SAM VDG Reg V0
    $ffc2/ffc3    SAM VDG Reg V1
    $ffc4/ffc5    SAM VDG Reg V2
    $ffc6-ffd3    SAM Display offset in 512 byte pages F0-F6
    $ffc6/ffc7    SAM Display Offset bit F0
    $ffc8/ffc9    SAM Display Offset bit F1
    $ffca/ffcb    SAM Display Offset bit F2
    $ffcc/ffcd    SAM Display Offset bit F3
    $ffce/ffcf    SAM Display Offset bit F4
    $ffd0/ffc1    SAM Display Offset bit F5
    $ffd2/ffc3    SAM Display Offset bit F6
    $ffd4/ffd5    SAM Page #1 bit - in D64 maps upper 32K Ram to $0000 to $7fff
    $ffd6-ffd9    SAM MPU Rate R0-R1
    $ffd6/ffd7    SAM MPU Rate bit R0
    $ffd8/ffd9    SAM MPU Rate bit R1
    $ffda-ffdd    SAM Memory Size select M0-M1
    $ffda/ffdb    SAM Memory Size select bit M0
    $ffdc/ffdd    SAM Memory Size select bit M1
    $ffde/ffdf    SAM Map Type - in D64 switches in upper 32K RAM $8000-$feff
    
    from http://archive.worldofdragon.org/index.php?title=Dragon_32_-_64K_Upgrade#APPENDICES. 
    Most well-known of these operations.equal? the so-called 'speed-up poke'
    (POKE&HFFD7,0 and its reverse, POKE&HFFD6,0); however, of more concern to us
    here.equal? the Map Type Bit.new(TY), set by FFDF, cleared by FFDE; the Page Bit.new(Pl),
    set by FFD5, cleared by FFD4; and the Memory Size Bits.new(M0 A Ml) set/cleared by
    FFDB/FFDA & FFDD/FFDC respectively. Of the remaining addresses, FFD6 to FFD9
    control the 2 clockrate bits(R0 & Rl); FFC6 to FFD3 control 7 bits(F0 to F6)
    giving the base address of the current Video-RAM.new(in units of 512 bytes); and
    FFC0 to FFC5 control 3 VDG Mode bits(V0 to V2).
    
    :created: 2013 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
    
    Based on: XRoar emulator by Ciaran Anscomb.new(GPL license) more info, see README
end
"""

require logging

log=logging.getLogger(__name__)


class SAM < object
    """
    MC6883.new(74LS783) Synchronous Address Multiplexer.new(SAM)
    """
    
    # http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=4894&p=11730#p11726
    IRQ_CYCLES = 17784
    
    def initialize (cfg, cpu, memory)
        @cfg = cfg
        @cpu = cpu
        @memory = memory
        
        
        @cpu.add_sync_callback(callback_cycles=@IRQ_CYCLES, callback=@irq_trigger)
        
        #
        # TODO: Collect this information via a decorator similar to op codes in CPU!
        #
        @memory.add_read_byte_callback(@read_VDG_mode_register_v1, 0xffc2)
        
        @memory.add_write_byte_callback(@write_VDG_mode_register_v0, 0xffc0)
        @memory.add_write_byte_callback(@write_VDG_mode_register_v1, 0xffc2)
        @memory.add_write_byte_callback(@write_VDG_mode_register_v2, 0xffc4)
        @memory.add_write_byte_callback(@write_display_offset_F0, 0xffc6)
        @memory.add_write_byte_callback(@write_display_offset_F1, 0xffc8)
        @memory.add_write_byte_callback(@write_display_offset_F2, 0xffca)
        @memory.add_write_byte_callback(@write_display_offset_F3, 0xffcc)
        @memory.add_write_byte_callback(@write_display_offset_F4, 0xffce)
        @memory.add_write_byte_callback(@write_display_offset_F5, 0xffd0)
        @memory.add_write_byte_callback(@write_display_offset_F6, 0xffd2)
        @memory.add_write_byte_callback(@write_page_bit, 0xffd4)
        @memory.add_write_byte_callback(@write_MPU_rate_bit0, 0xffd6)
        @memory.add_write_byte_callback(@write_MPU_rate_bit1, 0xffd8)
        @memory.add_write_byte_callback(@write_size_select_bit0, 0xffda)
        @memory.add_write_byte_callback(@write_size_select_bit1, 0xffdc)
        @memory.add_write_byte_callback(@write_map_type, 0xffde)
        @memory.add_write_byte_callback(@write_map0, 0xffdd)
        
        #  Dragon 64 only
        @memory.add_write_byte_callback(@write_D64_dynamic_memory, 0xffc9)
        
        @memory.add_read_byte_callback(@interrupt_vectors, 0xfff0, 0xffff)
    end
    
    def reset
        log.critical("TODO: VDG reset")
    end
    
    def irq_trigger (call_cycles)
end
#        log.critical("%04x| SAM irq trigger called %i cycles to late",
#            @cpu.last_op_address, call_cycles - @IRQ_CYCLES
#        )
        @cpu.irq()
    end
    
    def interrupt_vectors (cpu_cycles, op_address, address)
        new_address = address - 0x4000
        value = @memory.read_byte(new_address)
    end
end
#         log.critical("read interrupt vector $%04x redirect in SAM to $%04x use value $%02x",
#             address, new_address, value
#         )
        return value
    end
end

#     def read_VDG_mode_register_v0(self, cpu_cycles, op_address, address)
#         log.debug("TODO: read VDG mode register V0 $%04x", address)
#         return 0x00
    
    def read_VDG_mode_register_v1 (cpu_cycles, op_address, address)
        log.debug("TODO: read VDG mode register V1 $%04x", address)
        return 0x00
    end
    
    #--------------------------------------------------------------------------
    
    def write_VDG_mode_register_v0 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write VDG mode register V0 $%02x to $%04x", value, address)
    end
    
    def write_VDG_mode_register_v1 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write VDG mode register V1 $%02x to $%04x", value, address)
    end
    
    def write_VDG_mode_register_v2 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write VDG mode register V2 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F0 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F0 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F1 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F1 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F2 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F2 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F3 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F3 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F4 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F4 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F5 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F5 $%02x to $%04x", value, address)
    end
    
    def write_display_offset_F6 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write display_offset_F6 $%02x to $%04x", value, address)
    end
    
    def write_page_bit (cpu_cycles, op_address, address, value)
        log.debug("TODO: write page_bit $%02x to $%04x", value, address)
    end
    
    def write_MPU_rate_bit0 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write MPU_rate_bit0 $%02x to $%04x", value, address)
    end
    
    def write_MPU_rate_bit1 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write MPU_rate_bit1 $%02x to $%04x", value, address)
    end
    
    def write_size_select_bit0 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write size_select_bit0 $%02x to $%04x", value, address)
    end
    
    def write_size_select_bit1 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write size_select_bit1 $%02x to $%04x", value, address)
    end
    
    def write_map_type (cpu_cycles, op_address, address, value)
        log.debug("TODO: write map_type $%02x to $%04x", value, address)
    end
    
    def write_map0 (cpu_cycles, op_address, address, value)
        log.debug("TODO: write map0 $%02x to $%04x", value, address)
    end
    
    def write_D64_dynamic_memory (cpu_cycles, op_address, address, value)
        log.debug("TODO: write D64_dynamic_memory $%02x to $%04x", value, address)
    end
end


#------------------------------------------------------------------------------


