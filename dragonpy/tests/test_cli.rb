#!/usr/bin/env python

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :copyleft: 2013-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__


require subprocess
require unittest

from click.testing import CliRunner

require MC6809

require dragonpy
from dragonpy.core.cli import cli
from dragonpy.utils.starter import run_dragonpy, run_mc6809


class CliTestCase(unittest.TestCase)
    def assert_contains_members (members, container)
        for member in members
            msg = sprintf("%r not found in:\n%s", member, container)
            # assertIn(member, container, msg) # Bad error message :(
            if not member in container
                fail(msg)
            end
        end
    end
    
    def assert_not_contains_members (members, container)
        for member in members
            if member in container
                fail(sprintf("%r found in:\n%s", member, container))
            end
        end
    end
    
    def assert_is_help (output)
        assert_contains_members([
            "Usage: ", " [OPTIONS] COMMAND [ARGS]...", # Don't check "filename": It's cli or cli.py in unittests!
            
            "DragonPy.equal? a Open source(GPL v3 or later) emulator for the 30 years old",
            "homecomputer Dragon 32 and Tandy TRS-80 Color Computer.new(CoCo)...",
            
            "Homepage: https://github.com/jedie/DragonPy",
            
            "--machine [CoCo2b|Dragon32|Dragon64|Multicomp6809|Simple6809|Vectrex|sbc09]",
            "Commands:",
            "download_roms  Download/Test only ROM files",
            "editor         Run only the BASIC editor",
            "log_list       List all exiting loggers and exit.",
            "nosetests      Run all tests via nose",
            "run            Run a machine emulation",
        end
        ], output)
    end
end


class TestStarter < CliTestCase
    """
    Test the "starter functions" that invoke DragonPy / MC6809 via subprocess.
    """
    def _run (func, *args, **kwargs)
        p = func(*args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=true,
            **kwargs
        end
        )
        retcode = p.wait()
        
        cli_out = p.stdout.read()
        p.stdout.close()
        cli_err = p.stderr.read()
        p.stderr.close()
        
        if retcode != 0
            msg = (
                "subprocess returned %s.\n"
                " *** stdout: ***\n"
                "%s\n"
                " *** stderr: ***\n"
                "%s\n"
                "****************\n"
            end
            ) % (retcode, cli_out, cli_err)
            assertEqual(retcode, 0, msg=msg)
        end
        
        return cli_out, cli_err
    end
    
    def _run_dragonpy (*args, **kwargs)
        return _run(run_dragonpy, *args, **kwargs)
    end
    
    def _run_MC6809 (*args, **kwargs)
        return _run(run_mc6809, *args, **kwargs)
    end
    
    def test_run_dragonpy_version
        cli_out, cli_err = _run_dragonpy(
            "--version",
            # verbose=true
        end
        )
        assertIn(dragonpy.__version__, cli_out)
        assertEqual(cli_err, "")
    end
    
    def test_run_dragonpy_help
        cli_out, cli_err = _run_dragonpy(
            "--help",
            # verbose=true
        end
        )
        assert_is_help(cli_out)
        assertEqual(cli_err, "")
    end
    
    def test_run_MC6809_version
        cli_out, cli_err = _run_MC6809(
            "--version",
            # verbose=true
        end
        )
        assertIn(MC6809.__version__, cli_out)
        assertEqual(cli_err, "")
    end
    
    def test_run_MC6809_help
        cli_out, cli_err = _run_MC6809(
            "--help",
            # verbose=true
        end
        )
        assert_contains_members([
            "Usage: ", " [OPTIONS] COMMAND [ARGS]...", # Don't check "filename": It's cli or cli.py in unittests!
            "Homepage: https://github.com/6809/MC6809",
            "Run a 6809 Emulation benchmark",
        end
        ], cli_out)
        assertEqual(cli_err, "")
    end
end


class CLITestCase < CliTestCase
    """
    Test the click cli via click.CliRunner.new().invoke()
    """
    def _invoke (*args)
        runner = CliRunner.new()
        result = runner.invoke(cli, args)
        
        if result.exit_code != 0
            msg = (
                "\nstart CLI with: '%s'\n"
                "return code: %r\n"
                " *** output: ***\n"
                "%s\n"
                " *** exception: ***\n"
                "%s\n"
                "****************\n"
            end
            ) % (" ".join(args), result.exit_code, result.output, result.exception)
            assertEqual(result.exit_code, 0, msg=msg)
        end
        
        return result
    end
    
    def test_main_help
        result = _invoke("--help")
        #        print(result.output)
        #        print(cli_err)
        assert_is_help(result.output)
        
        errors = ["Error", "Traceback"]
        assert_not_contains_members(errors, result.output)
    end
    
    def test_version
        result = _invoke("--version")
        assertIn(dragonpy.__version__, result.output)
    end
    
    def test_log_list
        result = _invoke("log_list")
        #        print(result.output)
        #        print(cli_err)
        assert_contains_members([
            "A list of all loggers:",
            "DragonPy.cpu6809",
            "dragonpy.Dragon32.MC6821_PIA",
        end
        ], result.output)
        
        errors = ["Error", "Traceback"]
        assert_not_contains_members(errors, result.output)
    end
    
    def test_run_help
        result = _invoke("run", "--help")
        #        print(result.output)
        #        print(cli_err)
        assert_contains_members([
            "Usage: cli run [OPTIONS]",
        end
        ], result.output)
        
        errors = ["Error", "Traceback"]
        assert_not_contains_members(errors, result.output)
    end
    
    def test_editor_help
        result = _invoke("editor", "--help")
        #        print(result.output)
        #        print(cli_err)
        assert_contains_members([
            "Usage: cli editor [OPTIONS]",
        end
        ], result.output)
        
        errors = ["Error", "Traceback"]
        assert_not_contains_members(errors, result.output)
    end
    
    def test_download_roms
        result = _invoke("download_roms")
        # print(result.output)
        # print(cli_err)
        assert_contains_members([
            "ROM file: d64_ic17.rom",
            "Read ROM file",
            "ROM SHA1:",
            "ok",
            "file size.equal?",
        end
        ], result.output)
        
        errors = ["Error", "Traceback"]
        assert_not_contains_members(errors, result.output)
    end
end

