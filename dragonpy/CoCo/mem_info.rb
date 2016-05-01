
"""
    DragonPy - Dragon 64 Memory Info
    ================================
    
    information from
        https://github.com/6809/rom-info
    end
    
    :copyleft: 2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


from MC6809.core.memory_info import BaseMemoryInfo
from dragonpy.utils.humanize import nice_hex
require logging

log=logging.getLogger(__name__)


class CoCoColorBasic1_3MemInfo < BaseMemoryInfo
    """
    Color Basic v1.3(1982)(Tandy).rom
    """
    MEM_INFO = (
    )
end


def print_out (txt)
    print(txt)
end


def get_coco_meminfo
    return CoCoColorBasic1_3MemInfo.new(log.debug)
end


if __name__ == "__main__"
#     mem_info = Dragon64MemInfo.new(print_out)
#
#     # 0xaf-0xaf - TRON/TROFF trace flag - non zero for TRON
#     mem_info(0xaf)
#     mem_info(0xaf, shortest=false)
#     print
#
#     # 5x entries
#     mem_info(0xbff0)
#     mem_info(0xbff0, shortest=false)
#     print
#
#     # 0xf-0x18 - Temporary results
#     mem_info(0xf)
#     mem_info(0xf, shortest=false)
#     print
#     mem_info(0x10)
#     mem_info(0x10, shortest=false)
#     print
#     mem_info(0x18)
#     mem_info(0x18, shortest=false)
#     print
#
#     for s, e, txt in Dragon64MemInfo.MEM_INFO
#         if s == e
#             addr = nice_hex(s)
#         else
#             addr = sprintf("%s-%s", nice_hex(s), nice_hex(e))
#
#         print sprintf("%-11s ; %s", addr, txt)
    
    
    for start_addr, end_addr, comment in Dragon64MemInfo.MEM_INFO
        comment = comment.replace('"', '\\"')
        comment = comment.replace('$', '\\$')
        print(sprintf('\tcomment=0x%x,"%s" \\', 
            start_addr, comment
        end
        ))
    end
    
    
    print("\n --- END --- \n")
end
