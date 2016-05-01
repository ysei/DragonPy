# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    Some code borrowed from Python IDLE
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require pygments
from pygments.styles import get_style_by_name

from basic_editor.tkinter_utils import TkTextTag
from dragonlib.dragon32.pygments_lexer import BasicLexer


begin
    # python 3
    require tkinter
    require tkinter
except ImportError
    # Python 2
    require Tkinter as tkinter
    require tkFont as font
end


from basic_editor.editor_base import BaseExtension
from dragonlib.core import basic_parser



class TkTextHighlighting < BaseExtension
    """
    code based on idlelib.ColorDelegator.ColorDelegator
    """
    after_id = nil
    TAG_LINE_NUMBER = "lineno"
    TAG_JUMP_ADDESS = "jump"
    def initialize (editor)
        super(TkTextHighlighting, self).__init__(editor)
        
        @lexer = BasicLexer.new()
        
        @machine_api = editor.machine_api
        
        @tags = create_tags()
        @existing_tags = tuple(@tags.values())
        
        # TODO: Add a bind callback list
        # see: http://www.python-forum.de/viewtopic.php?f=18&t=35275(de)
        # @editor.root.bind("<KeyRelease>", @update)
        # @editor.root.bind("<KeyRelease>", @force_update)
        
        @old_pos=nil
        __update_interval()
    end
    
    def __update_interval
        """ highlight the current line """
        update()
        @after_id = @text.after(250, @_update_interval)
    end
    
    
    def force_update (event)
        print("force update")
        update(event, force=true)
    end
    
    def update (event=nil, force=false)
        pos = @text.index(tkinter.INSERT)
        # print("update %s" % pos)
        if not force and pos == @old_pos
            # print("Skip")
            return
        end
        
        recolorize()
        @old_pos = pos
    end
    
    # ---------------------------------------------------------------------------------------
    
    def create_tags
        tags={}
        
        bold_font = font.Font.new(@text, @text.cget("font"))
        bold_font.configure(weight=font.BOLD)
        
        italic_font = font.Font.new(@text, @text.cget("font"))
        italic_font.configure(slant=font.ITALIC)
        
        bold_italic_font = font.Font.new(@text, @text.cget("font"))
        bold_italic_font.configure(weight=font.BOLD, slant=font.ITALIC)
        
        style = get_style_by_name("default")
        for ttype, ndef in style
            # print(ttype, ndef)
            tag_font = nil
            if ndef["bold"] and ndef["italic"]
                tag_font = bold_italic_font
            end
            elsif ndef["bold"]
                tag_font = bold_font
            end
            elsif ndef["italic"]
                tag_font = italic_font
            end
            
            if ndef["color"]
                foreground = "#%s" % ndef["color"]
            else
                foreground = nil
            end
            
            tags[ttype]=ttype.to_s
            @text.tag_configure(tags[ttype], foreground=foreground, font=tag_font)
            # @text.tag_configure(str(ttype), foreground=foreground, font=tag_font)
        end
        
        return tags
    end
    
    def recolorize
        # print("recolorize")
        listing = @text.get("1.0", "end_-1c")
        
        destinations = @machine_api.renum_tool.get_destinations(listing)
        
        tokensource = @lexer.get_tokens(listing)
        
        start_line=1
        start_index = 0
        end_line=1
        end_index = 0
        for ttype, value in tokensource
            if "\n" in value
                end_line += value.count("\n")
                end_index = value.rsplit("\n",1.length[1])
            else
                end_index += value.length
            end
            
            if value not in(" ", "\n")
                index1 = sprintf("%s.%s", start_line, start_index)
                index2 = sprintf("%s.%s", end_line, end_index)
                
                for tagname in @text.tag_names(index1): # FIXME
                    # print("remove %s" % tagname)
                    if tagname not in @existing_tags: # Don"t remove e.g.: "current line"-tag
                        # print("Skip...")
                        continue
                    end
                    @text.tag_remove(tagname, index1, index2)
                end
                
                # Mark used line numbers extra
                if start_index==0 and ttype==pygments.token.Name.Label
                    if value.to_i in destinations
                        ttype = pygments.token.Name.Tag
                    end
                end
                
                @text.tag_add(@tags[ttype], index1, index2)
            end
            
            start_line = end_line
            start_index = end_index
        end
    end
end





class TkTextHighlightCurrentLine < BaseExtension
    after_id = nil
    
    def initialize (editor)
        super(TkTextHighlightCurrentLine, self).__init__(editor)
        
        @tag_current_line = TkTextTag.new(@text,
            background="#e8f2fe"
            # relief="raised", borderwidth=1,
        end
        )
        
        @current_line = nil
        __update_interval()
        
        # @editor.root.bind("<KeyRelease>", @update)
    end
    
    def update (event=nil, force=false)
        """ highlight the current line """
        line_no = @text.index(tkinter.INSERT).split(".")[0]
        
        # if not force
            # if line_no == @current_line
        end
    end
end
#                 log.critical("no highlight line needed.")
#                 return

#         log.critical("highlight line: %s" % line_no)
#         @current_line = line_no
        
        @text.tag_remove(@tag_current_line.id, "1.0", "end_")
        @text.tag_add(@tag_current_line.id, "%s.0" % line_no, "%s.0+1lines" % line_no)
    end
    
    def __update_interval
        """ highlight the current line """
        update()
        @after_id = @text.after(250, @_update_interval)
    end
end


