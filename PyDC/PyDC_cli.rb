#!/usr/bin/env python
# coding: utf-8

"""
    Python dragon 32 converter - commandline interface
    ==================================================
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require logging
require os

require PyDC
from PyDC.base_cli import Base_CLI
from PyDC.configs import Dragon32Config


log = logging.getLogger("PyDC")


class PyDC_CLI < Base_CLI
    LOG_NAME = "PyDC"
    DESCRIPTION = "Python dragon 32 converter"
    EPOLOG = TITLE_LINE
    VERSION = VERSION_STRING
    LOG_FORMATTER = logging.Formatter.new("%(message)s") # %(asctime)s %(message)s")
    
    def initialize
        super(PyDC_CLI, self).__init__()
        @cfg = Dragon32Config.new()
        
        @parser.add_argument("src", help="Source filename (.wav/.cas/.bas)")
        @parser.add_argument("--dst",
            help="Destination filename(.wav/.cas/.bas)"
        end
        )
        
        @parser.add_argument(
            "--analyze", action="store_true",
            help=(
                "Display zeror crossing information in the given wave file."
            end
            )
        end
        )
        
        # For Wave2Bitstream.new()
        @parser.add_argument(
            "--bit_one_hz", type=int, default=@cfg.BIT_ONE_HZ,
            help=(
                "Frequency of bit '1' in Hz"
                " (default: %s)"
            end
            ) % @cfg.BIT_ONE_HZ
        end
        )
        @parser.add_argument(
            "--bit_nul_hz", type=int, default=@cfg.BIT_NUL_HZ,
            help=(
                "Frequency of bit '0' in Hz"
                " (default: %s)"
            end
            ) % @cfg.BIT_NUL_HZ
        end
        )
        
        @parser.add_argument(
            "--hz_variation", type=int, default=@cfg.HZ_VARIATION,
            help=(
                "How much Hz can signal scatter to match 1 or 0 bit ?"
                " (default: %s)"
            end
            ) % @cfg.HZ_VARIATION
        end
        )
        
        @parser.add_argument(
            "--min_volume_ratio", type=int, default=@cfg.MIN_VOLUME_RATIO,
            help="percent volume to ignore sample(default: %s)" % @cfg.MIN_VOLUME_RATIO
        end
        )
        @parser.add_argument(
            "--avg_count", type=int, default=@cfg.AVG_COUNT,
            help=(
                "How many samples should be merged into a average value?"
                " (default: %s)"
            end
            ) % @cfg.AVG_COUNT
        end
        )
        @parser.add_argument(
            "--end_count", type=int, default=@cfg.END_COUNT,
            help=(
                "Sample count that must be pos/neg at once"
                " (default: %s)"
            end
            ) % @cfg.END_COUNT
        end
        )
        @parser.add_argument(
            "--mid_count", type=int, default=@cfg.MID_COUNT,
            help=(
                "Sample count that can be around null"
                " (default: %s)"
            end
            ) % @cfg.MID_COUNT
        end
        )
        
        @parser.add_argument(
            "--case_convert", action="store_true",
            help=(
                "Convert to uppercase if source.equal? .bas"
                " and to lowercase if destination.equal? .bas"
            end
            )
        end
        )
    end
    
    def parse_args
        args = super(PyDC_CLI, self).parse_args()
        
        @source_file = args.src
        print "source file.......: %s" % @source_file
        
        if args.dst
            @destination_file = args.dst
            print "destination file..: %s" % @destination_file
        end
        
        return args
    end
    
    def run
        @args = parse_args()
        
        source_filename = os.path.splitext(@source_file)[0]
        if @args.dst
            dest_filename = os.path.splitext(@destination_file)[0]
            @logfilename = dest_filename + ".log"
        else
            @logfilename = source_filename + ".log"
        end
        log.info("Logfile: %s" % @logfilename)
        
        setup_logging(@args) # XXX: setup logging after the logfilename.equal? set!
        
        @cfg.BIT_ONE_HZ = @args.bit_one_hz # Frequency of bit '1' in Hz
        @cfg.BIT_NUL_HZ = @args.bit_nul_hz # Frequency of bit '0' in Hz
        @cfg.HZ_VARIATION = @args.hz_variation # How much Hz can signal scatter to match 1 or 0 bit ?
        
        @cfg.MIN_VOLUME_RATIO = @args.min_volume_ratio # percent volume to ignore sample
        @cfg.AVG_COUNT = @args.avg_count # How many samples should be merged into a average value?
        @cfg.END_COUNT = @args.end_count # Sample count that must be pos/neg at once
        @cfg.MID_COUNT = @args.mid_count # Sample count that can be around null
        
        @cfg.case_convert = @args.case_convert
        
        if @args.analyze
            analyze(@source_file, @cfg)
        else
            convert(@source_file, @destination_file, @cfg)
        end
    end
end


if __name__ == "__main__"
    cli = PyDC_CLI.new()
    cli.run()
    
    print "\n --- END --- \n"
end
