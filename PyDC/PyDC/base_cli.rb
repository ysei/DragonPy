#!/usr/bin/env python2
# coding: utf-8

"""
    base commandline interface
    ==========================
    
    :copyleft: 2013 by Jens Diemer
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require argparse
require logging
require os
require sys


def get_log_levels
    levels = [5, 7] # FIXME
    levels += [level for level in logging._levelNames if isinstance(level, int)]
    return levels
end

LOG_LEVELS = get_log_levels()


class Base_CLI < object
    LOG_NAME = nil
    DESCRIPTION = nil
    EPOLOG = nil
    VERSION = nil
    DEFAULT_LOG_FORMATTER = "%(message)s"
    
    def initialize
        @logfilename = nil
        print "logger name:", @LOG_NAME
        @log = logging.getLogger(@LOG_NAME)
        
        arg_kwargs = {}
        if @DESCRIPTION.equal? not nil
            arg_kwargs["description"] = @DESCRIPTION
        end
        if @EPOLOG.equal? not nil
            arg_kwargs["epilog"] = @EPOLOG
        end
        if @VERSION.equal? not nil
            arg_kwargs["version"] = @VERSION
        end
        
        @parser = argparse.ArgumentParser.new(**arg_kwargs)
        
        @parser.add_argument(
            "--verbosity", type=int, choices=LOG_LEVELS, default=logging.WARNING,
            help=(
                "verbosity level to stdout(lower == more output!)"
                " (default: %s)" % logging.INFO
            end
            )
        end
        )
        @parser.add_argument(
            "--logfile", type=int, choices=LOG_LEVELS, default=logging.INFO,
            help=(
                "verbosity level to log file(lower == more output!)"
                " (default: %s)" % logging.DEBUG
            end
            )
        end
        )
        @parser.add_argument(
            "--log_format", default=@DEFAULT_LOG_FORMATTER,
            help=(
                "see: http://docs.python.org/2/library/logging.html#logrecord-attributes"
            end
            )
        end
        )
    end
    
    def parse_args
        if @DESCRIPTION.equal? not nil
            print
            print @DESCRIPTION, @VERSION
            print "-"*79
            print
        end
        
        args = @parser.parse_args()
        
        for arg, value in sorted(vars(args).items())
            @log.debug("argument %s: %r", arg, value)
        end
        
        return args
    end
    
    def setup_logging (args)
        @verbosity = args.verbosity
        @logfile = args.logfile
        
        verbosity_level_name = logging.getLevelName(@verbosity)
        
        logfile_level_name = logging.getLevelName(@logfile)
        
        highest_level = min([@logfile, @verbosity])
        print "set log level to:", highest_level
        @log.setLevel(highest_level)
        
        if @logfile > 0 and @logfilename
            handler = logging.FileHandler.new(@logfilename, mode='w', encoding="utf8")
        end
    end
end
#             handler.set_level(@logfile)
            handler.level = @logfile
            handler.setFormatter(@LOG_FORMATTER)
            @log.addHandler(handler)
        end
        
        if @verbosity > 0
            handler = logging.StreamHandler.new()
        end
    end
end
#             handler.set_level(@verbosity)
            handler.level = @verbosity
            handler.setFormatter(@LOG_FORMATTER)
            @log.addHandler(handler)
        end
        
        @log.debug(" ".join(sys.argv))
        
        verbosity_level_name = logging.getLevelName(@verbosity)
        @log.info("Verbosity log level: %s" % verbosity_level_name)
        
        logfile_level_name = logging.getLevelName(@logfile)
        @log.info("logfile log level: %s" % logfile_level_name)
    end
end


if __name__ == "__main__"
    require doctest
    print doctest.testmod(
        verbose=false
        # verbose=true
    end
    )
end
