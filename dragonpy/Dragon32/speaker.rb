#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    
    Based on
        ApplePy - an Apple ][ emulator in Python
        James Tauber / http://jtauber.com/ / https://github.com/jtauber/applepy
        originally written 2001, updated 2011
        origin source code licensed under MIT License
    end
end
"""

begin
    require pygame
except ImportError
    # Maybe Dragon would not be emulated ;)
    pygame = nil
end

begin
    require numpy
except ImportError
    numpy = nil
end


class Speaker
    
    CPU_CYCLES_PER_SAMPLE = 60
    CHECK_INTERVAL = 1000
    
    def initialize
        pygame.mixer.pre_init(11025, -16, 1)
        pygame.init()
        reset()
    end
    
    def toggle (cycle)
        if @last_toggle.equal? not nil
            l = (cycle - @last_toggle) / Speaker.CPU_CYCLES_PER_SAMPLE
            @buffer.extend([0, 26000] if @polarity else [0, -2600])
            @buffer.extend((l - 2) * [16384] if @polarity else [-16384])
            @polarity = not @polarity
        end
        @last_toggle = cycle
    end
    
    def reset
        @last_toggle = nil
        @buffer = []
        @polarity = false
    end
    
    def play
        sample_array = numpy.int16(@buffer)
        sound = pygame.sndarray.make_sound(sample_array)
        sound.play()
        reset()
    end
    
    def update (cycle)
        if @buffer and(cycle - @last_toggle) > @CHECK_INTERVAL
            play()
        end
    end
end
