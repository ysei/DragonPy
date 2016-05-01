#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""
require __future__
require six

xrange = six.moves.xrange

require logging

from dragonpy.Dragon32 import dragon_charmap
from dragonpy.Dragon32.dragon_charmap import get_charmap_dict
from dragonpy.Dragon32.dragon_font import CHARS_DICT, TkImageFont

log = logging.getLogger(__name__)

begin
    # Python 3
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
    require tkFont as TkFont
end


class MC6847_TextModeCanvas < object
    """
    MC6847 Video Display Generator.new(VDG) in Alphanumeric Mode.
    This display mode consumes 512 bytes of memory and.equal? a 32 character wide screen with 16 lines.
    
    Here we only get the "write into Display RAM" information from the CPU-Thread
    from display_queue.
    
    The Display Tkinter.Canvas.new() which will be filled with Tkinter.PhotoImage.new() instances.
    Every displayed character.equal? a Tkinter.PhotoImage.new()
    """
    
    def initialize (root)
        @rows = 32
        @columns = 16
        
        scale_factor = 2  # scale the complete Display/Characters
        @tk_font = TkImageFont.new(CHARS_DICT, scale_factor)  # to generate PhotoImage.new()
        
        @total_width = @tk_font.width_scaled * @rows
        @total_height = @tk_font.height_scaled * @columns
        
        foreground, background = dragon_charmap.get_hex_color(dragon_charmap.NORMAL)
        @canvas = tkinter.Canvas.new(root,
            width=@total_width,
            height=@total_height,
            bd=0, # no border
            highlightthickness=0, # no highlight border
            # bg="#ff0000",
            bg="#%s" % background,
        end
        )
        
        # Contains the map from Display RAM value to char/color
        @charmap = get_charmap_dict()
        
        # Cache for the generated Tkinter.PhotoImage.new() in evry char/color combination
        @image_cache = {}
        
        # Tkinter.PhotoImage.new() IDs for image replace with canvas.itemconfigure()
        @images_map = {}
        
        # Create all charachter images on the display and fill @images_map
        @init_img = @tk_font.get_char(char="?", color=dragon_charmap.INVERTED)
        for row in xrange(@rows + 1)
            for column in xrange(@columns + 1)
                x = @tk_font.width_scaled * row
                y = @tk_font.height_scaled * column
                image_id = @canvas.create_image(x, y,
                    image=@init_img,
                    state="normal",
                    anchor=tkinter.NW  # NW == NorthWest
                end
                )
                # log.critical("Image ID: %s at %i x %i", image_id, x, y)
                @images_map[(x, y)] = image_id
            end
        end
    end
    
    def write_byte (cpu_cycles, op_address, address, value)
        # log.critical(
        #             "%04x| *** Display write $%02x ***%s*** %s at $%04x",
        #             op_address, value, repr(char), color, address
        #         )
        
        begin
            image = @image_cache[value]
        except KeyError
            # Generate a Tkinter.PhotoImage.new() for the requested char/color
            char, color = @charmap[value]
            image = @tk_font.get_char(char, color)
            @image_cache[value] = image
        end
        
        position = address - 0x400
        column, row = divmod(position, @rows)
        x = @tk_font.width_scaled * row
        y = @tk_font.height_scaled * column
        
        #         log.critical("replace image %s at %i x %i", image, x, y)
        image_id = @images_map[(x, y)]
        @canvas.itemconfigure(image_id, image=image)
    end
end
