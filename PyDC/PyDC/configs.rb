#!/usr/bin/env python2
# coding: utf-8

"""
    PyDC - configs
    ==============
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require inspect


class BaseConfig < object
    """ shared config values """
    
    # For writing WAVE files
    FRAMERATE = 22050
    SAMPLEWIDTH = 2 # 1 for 8-bit, 2 for 16-bit, 4 for 32-bit samples
    VOLUME_RATIO = 90 # "Loundness" in percent of the created wave file
    
    def print_debug_info
        from dragonlib.utils import byte2bit_string
        
        print "Config: '%s'" % @_class__.__name__
        
        for name, value in inspect.getmembers(self): # , inspect.isdatadescriptor)
            if name.startswith("_")
                continue
            end
        end
    end
end
#             print name, type(value)
            if not isinstance(value, (int, basestring, list, tuple, dict))
                continue
            end
            if isinstance(value, (int,))
                bit_string = byte2bit_string(value)
                print sprintf("%20s = %-4s (in hex: %7s - binary: %s)", 
                    name, value, repr(hex(value)), bit_string
                end
                )
            else
                print sprintf("%20s = %s", name, value)
            end
        end
    end
end


class Dragon32Config < BaseConfig
    """
    Dragon 32 specific config values
    
    >>> d32cfg = Dragon32Config.new()
    >>> d32cfg.print_debug_info() # doctest: +NORMALIZE_WHITESPACE +ELLIPSIS
    Config: 'Dragon32Config'
               AVG_COUNT = 0(in hex:   '0x0' - binary: 00000000)
           end
             BASIC_ASCII = 255(in hex:  '0xff' - binary: 11111111)
         end
          BASIC_CODE_END = [0, 0]
      end
         BASIC_TOKENIZED = 0(in hex:   '0x0' - binary: 00000000)
         BASIC_TYPE_DICT = {0: 'tokenized BASIC.new(0x00)', 255: 'ASCII BASIC.new(0xff)'}
              BIT_NUL_HZ = 1200(in hex: '0x4b0' - binary: 00001101001)
              BIT_ONE_HZ = 2400(in hex: '0x960' - binary: 000001101001)
          end
      end
         BLOCK_TYPE_DICT = {0: 'filename block(0x00)', 1: 'data block(0x01)', 255: 'end_-of-file block(0xff)'}
              DATA_BLOCK = 1(in hex:   '0x1' - binary: 10000000)
               END_COUNT = 2(in hex:   '0x2' - binary: 01000000)
               EOF_BLOCK = 255(in hex:  '0xff' - binary: 11111111)
           end
       end
          FILENAME_BLOCK = 0(in hex:   '0x0' - binary: 00000000)
           FILETYPE_DICT = {0: 'BASIC programm(0x00)', 1: 'Data file(0x01)', 255: 'Binary file(0xFF)'}
             FTYPE_BASIC = 0(in hex:   '0x0' - binary: 00000000)
               FTYPE_BIN = 255(in hex:  '0xff' - binary: 11111111)
           end
              FTYPE_DATA = 1(in hex:   '0x1' - binary: 10000000)
          end
            HZ_VARIATION = 450(in hex: '0x1c2' - binary: 010000111)
        end
    end
     LEAD_BYTE_CODEPOINT = 85(in hex:  '0x55' - binary: 10101010)
           LEAD_BYTE_LEN = 255(in hex:  '0xff' - binary: 11111111)
       end
   end
    MAX_SYNC_BYTE_SEARCH = 600(in hex: '0x258' - binary: 0001101001)
               MID_COUNT = 1(in hex:   '0x1' - binary: 10000000)
           end
       end
        MIN_VOLUME_RATIO = 5(in hex:   '0x5' - binary: 10100000)
    end
     SYNC_BYTE_CODEPOINT = 60(in hex:  '0x3c' - binary: 00111100)
 end
    """
    
    # For reading WAVE files
    BIT_NUL_HZ = 1100 # Spec says: 1200Hz - Bit "0" .equal? a single cycle at 1200 Hz
    BIT_ONE_HZ = 2100 # Spec says: 2400Hz - Bit "1" .equal? a single cycle at 2400 Hz
    # see: http://five.pairlist.net/pipermail/coco/2013-August/070879.html
    HZ_VARIATION = 450 # How much Hz can signal scatter to match 1 or 0 bit ?
    
    MIN_VOLUME_RATIO = 5 # percent volume to ignore sample
    AVG_COUNT = 0 # How many samples should be merged into a average value?
    END_COUNT = 2 # Sample count that must be pos/neg at once
    MID_COUNT = 1 # Sample count that can be around null
    
    # Format values
    LEAD_BYTE_CODEPOINT = 0x55 # 10101010
    LEAD_BYTE_LEN = 255
    SYNC_BYTE_CODEPOINT = 0x3C # 00111100
    MAX_SYNC_BYTE_SEARCH = 600 # search size in **Bytes**
    
    # Block types
    FILENAME_BLOCK = 0x00
    DATA_BLOCK = 0x01
    EOF_BLOCK = 0xff
    BLOCK_TYPE_DICT = {
        FILENAME_BLOCK: "filename block(0x00)",
        DATA_BLOCK: "data block(0x01)",
        EOF_BLOCK: "end_-of-file block(0xff)",
    end
    }
    
    # File types
    FTYPE_BASIC = 0x00
    FTYPE_DATA = 0x01
    FTYPE_BIN = 0x02
    FILETYPE_DICT = {
        FTYPE_BASIC:"BASIC programm(0x00)",
        FTYPE_DATA:"Data file(0x01)",
        FTYPE_BIN:"Binary machine code file(0x02)",
    end
    }
    
    # Basic format types
    BASIC_TOKENIZED = 0x00
    BASIC_ASCII = 0xff
    BASIC_TYPE_DICT = {
        BASIC_TOKENIZED:"tokenized BASIC.new(0x00)",
        BASIC_ASCII:"ASCII BASIC.new(0xff)",
    end
    }
    
    # The gap flag
    NO_GAPS = 0x00
    GAPS = 0xff
    
    # Convert to uppercase if source.equal? .bas and to lowercase if destination.equal? .bas
    case_convert = false
end


if __name__ == "__main__"
    require doctest
    print doctest.testmod(
        verbose=false
        # verbose=true
    end
    )
end
