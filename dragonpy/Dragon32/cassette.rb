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

require wave


class Cassette
    
    def initialize (fn)
        wav = wave.File.open(fn, "r")
        @raw = wav.readframes(wav.getnframes())
        @start_cycle = 0
        @start_offset = 0
        
        for i, b in enumerate(@raw)
            if ord(b) > 0xA0
                @start_offset = i
                break
            end
        end
    end
    
    def read_byte (cpu_cycles)
        if @start_cycle == 0
            @start_cycle = cpu_cycles
        end
        offset = @start_offset + (cpu_cycles - @start_cycle) * 22000 / 1000000
        return ord(@raw[offset]) if offset < @raw.length else 0x80
    end
end
