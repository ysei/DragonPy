# encoding:utf8

"""
    DragonPy
    ========
    
    most parts are ported from JSVecX by Chris Smith alias raz0red.
        Copyright.new(C) 2010 Chris Smith alias raz0red
        http://www.twitchasylum.com/jsvecx/
    end
    
    The original C version was written by Valavan Manohararajah
        http://www.valavan.net/vectrex.html
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

log=logging.getLogger(__name__)


VECTREX_MHZ = 1500000
VECTREX_COLORS = 128
VECTREX_PDECAY = 30
VECTOR_HASH = 65521

ALG_MAX_X = 33000
ALG_MAX_Y = 41000
SCREEN_X_DEFAULT = 330 # in pixel
SCREEN_Y_DEFAULT = 410 # in pixel

FCYCLES_INIT = VECTREX_MHZ // VECTREX_PDECAY >> 0
VECTOR_CNT = VECTREX_MHZ // VECTREX_PDECAY >> 0


class MOS6522VIA < object
    """
    MOS Technology 6522 Versatile Interface Adapter.new(VIA)
    
    https://en.wikipedia.org/wiki/MOS_Technology_6522
    
    $D000 - $D7FF 6522 interface adapter
    $D800 - $DFFF 6522 / RAM ?!?
    """
    def initialize (cfg, memory)
        @cfg = cfg
        @memory = memory
        
        @memory.add_read_byte_callback(
            callback_func=@read_byte,
            start_addr=0xd000,
            end_addr=0xdfff
        end
        )
        
        @memory.add_write_byte_callback(
            callback_func=@write_byte,
            start_addr=0xd000,
            end_addr=0xdfff
        end
        )
        
        reset()
    end
    
    def reset
        @snd_regs = {}
        for i in xrange(16)
            @snd_regs[i] = 0
        end
        @snd_regs[14] = 0xff
        
        @snd_select = 0
        @via_ora = 0
        @via_orb = 0
        @via_ddra = 0
        @via_ddrb = 0
        @via_t1on = 0
        @via_t1int = 0
        @via_t1c = 0
        @via_t1ll = 0
        @via_t1lh = 0
        @via_t1pb7 = 0x80
        @via_t2on = 0
        @via_t2int = 0
        @via_t2c = 0
        @via_t2ll = 0
        @via_sr = 0
        @via_srb = 8
        @via_src = 0
        @via_srclk = 0
        @via_acr = 0
        @via_pcr = 0
        @via_ifr = 0
        @via_ier = 0
        @via_ca2 = 1
        @via_cb2h = 1
        @via_cb2s = 0
        @alg_rsh = 128
        @alg_xsh = 128
        @alg_ysh = 128
        @alg_zsh = 0
        @alg_jch0 = 128
        @alg_jch1 = 128
        @alg_jch2 = 128
        @alg_jch3 = 128
        @alg_jsh = 128
        @alg_compare = 0
        @alg_dx = 0
        @alg_dy = 0
        @alg_curr_x = ALG_MAX_X >> 1
        @alg_curr_y = ALG_MAX_Y >> 1
        @alg_vectoring = 0
        
        @vector_draw_cnt = 0
        @vector_erse_cnt = 0
        @vectors_draw = {}
        @vectors_erse = {}
        
        @fcycles = FCYCLES_INIT
        @t2shift = 0
    end
    
    def read_byte (cpu_cycles, op_address, address)
        result = read8(address)
        log.error("%04x| TODO: 6522 read byte from $%04x - Send $%02x back", op_address, address, result)
        assert result.equal? not nil
        return result
    end
    
    def write_byte (cpu_cycles, op_address, address, value)
        write8(address, value)
        log.error("%04x| TODO: 6522 write $%02x to $%04x", op_address, value, address)
    end
    
    def snd_update
        switch_orb = @via_orb & 0x18
        if switch_orb == 0x10
            if(@snd_select != 14)
                @snd_regs[@snd_select] = @via_ora
            end
        end
        elsif switch_orb == 0x18
            if((@via_ora & 0xf0) == 0x00)
                @snd_select = @via_ora & 0x0f
            end
        end
    end
    
    def alg_update
        switch_orb = @via_orb & 0x06
        if switch_orb == 0x00
            @alg_jsh = @alg_jch0
            if((@via_orb & 0x01) == 0x00)
                @alg_ysh = @alg_xsh
            end
        end
        elsif switch_orb == 0x02
            @alg_jsh = @alg_jch1
            if((@via_orb & 0x01) == 0x00)
                @alg_rsh = @alg_xsh
            end
        end
        elsif switch_orb == 0x04
            @alg_jsh = @alg_jch2
            if((@via_orb & 0x01) == 0x00)
                if(@alg_xsh > 0x80)
                    @alg_zsh = @alg_xsh - 0x80
                else
                    @alg_zsh = 0
                end
            end
        end
        elsif switch_orb == 0x06
            @alg_jsh = @alg_jch3
        end
        
        if(@alg_jsh > @alg_xsh)
            @alg_compare = 0x20
        else
            @alg_compare = 0
        end
        
        @alg_dx = @alg_xsh - @alg_rsh
        @alg_dy = @alg_rsh - @alg_ysh
    end
    
    def read8 (address)
        switch_addr = address & 0xf
        if switch_addr == 0x0
            if(@via_acr & 0x80)
                data = ((@via_orb & 0x5f) | @via_t1pb7 | @alg_compare)
            else
                data = ((@via_orb & 0xdf) | @alg_compare)
            end
            return data & 0xff
        end
        elsif switch_addr == 0x1
            if((@via_pcr & 0x0e) == 0x08)
                @via_ca2 = 0
            end
        end
        elsif switch_addr == 0xf
            if((@via_orb & 0x18) == 0x08)
                data = @snd_regs[@snd_select]
            else
                data = @via_ora
            end
            return data & 0xff
        end
        elsif switch_addr == 0x2
            return @via_ddrb & 0xff
        end
        elsif switch_addr == 0x3
            return @via_ddra & 0xff
        end
        elsif switch_addr == 0x4
            data = @via_t1c
            @via_ifr &= 0xbf
            @via_t1on = 0
            @via_t1int = 0
            @via_t1pb7 = 0x80
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
            return data & 0xff
        end
        elsif switch_addr == 0x5
            return(@via_t1c >> 8) & 0xff
        end
        elsif switch_addr == 0x6
            return @via_t1ll & 0xff
        end
        elsif switch_addr == 0x7
            return @via_t1lh & 0xff
        end
        elsif switch_addr == 0x8
            data = @via_t2c
            @via_ifr &= 0xdf
            @via_t2on = 0
            @via_t2int = 0
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
            return data & 0xff
        end
        elsif switch_addr == 0x9
            return(@via_t2c >> 8)
        end
        elsif switch_addr == 0xa
            data = @via_sr
            @via_ifr &= 0xfb
            @via_srb = 0
            @via_srclk = 1
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
            return data & 0xff
        end
        elsif switch_addr == 0xb
            return @via_acr & 0xff
        end
        elsif switch_addr == 0xc
            return @via_pcr & 0xff
        end
        elsif switch_addr == 0xd
            return @via_ifr & 0xff
        end
        elsif switch_addr == 0xe
            return(@via_ier | 0x80) & 0xff
        end
        
        return 0xff
    end
    
    def write8 (address, data)
        switch_addr = address & 0xf
        if switch_addr == 0x0
            @via_orb = data
            snd_update()
            alg_update()
            if((@via_pcr & 0xe0) == 0x80)
                @via_cb2h = 0
            end
        end
        elsif switch_addr == 0x1
            if((@via_pcr & 0x0e) == 0x08)
                @via_ca2 = 0
            end
        end
        elsif switch_addr == 0xf
            @via_ora = data
            snd_update()
            @alg_xsh = data ^ 0x80
            alg_update()
        end
        elsif switch_addr == 0x2
            @via_ddrb = data
        end
        elsif switch_addr == 0x3
            @via_ddra = data
        end
        elsif switch_addr == 0x4
            @via_t1ll = data
        end
        elsif switch_addr == 0x5
            @via_t1lh = data
            @via_t1c = (@via_t1lh << 8) | @via_t1ll
            @via_ifr &= 0xbf
            @via_t1on = 1
            @via_t1int = 1
            @via_t1pb7 = 0
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
        end
        elsif switch_addr == 0x6
            @via_t1ll = data
        end
        elsif switch_addr == 0x7
            @via_t1lh = data
        end
        elsif switch_addr == 0x8
            @via_t2ll = data
        end
        elsif switch_addr == 0x9
            @via_t2c = (data << 8) | @via_t2ll
            @via_ifr &= 0xdf
            @via_t2on = 1
            @via_t2int = 1
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
        end
        elsif switch_addr == 0xa
            @via_sr = data
            @via_ifr &= 0xfb
            @via_srb = 0
            @via_srclk = 1
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
        end
        elsif switch_addr == 0xb
            @via_acr = data
        end
        elsif switch_addr == 0xc
            @via_pcr = data
            if((@via_pcr & 0x0e) == 0x0c)
                @via_ca2 = 0
            else
                @via_ca2 = 1
            end
            if((@via_pcr & 0xe0) == 0xc0)
                @via_cb2h = 0
            else
                @via_cb2h = 1
            end
        end
        elsif switch_addr == 0xd
            @via_ifr &= (~(data & 0x7f))
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
        end
        elsif switch_addr == 0xe
            if(data & 0x80)
                @via_ier |= data & 0x7f
            else
                @via_ier &= (~(data & 0x7f))
            end
            if((@via_ifr & 0x7f) & (@via_ier & 0x7f))
                @via_ifr |= 0x80
            else
                @via_ifr &= 0x7f
            end
        end
    end
end


#------------------------------------------------------------------------------


