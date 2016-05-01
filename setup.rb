#!/usr/bin/env python
# coding: utf-8

"""
    distutils setup
    ~~~~~~~~~~~~~~~
    
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require setuptools

require os
require sys
require subprocess
require shutil

require dragonpy

PACKAGE_ROOT = os.path.dirname(os.path.abspath(__file__))


# convert creole to ReSt on-the-fly, see also
# https://code.google.com/p/python-creole/wiki/UseInSetup
begin
    from creole.setup_utils import get_long_description
rescue ImportError => err
    if "check" in sys.argv or "register" in sys.argv or "sdist" in sys.argv or "--long-description" in sys.argv
        raise ImportError.new("%s - Please install python-creole >= v0.8 -  e.g.: pip install python-creole" % err)
    end
    long_description = nil
else
    long_description = get_long_description(PACKAGE_ROOT)
end



if "publish" in sys.argv
    """
    'publish' helper for setup.py
    
    Build and upload to PyPi, if...
        ... __version__ doesn't contains "dev"
        ... we are on git 'master' branch
        ... git repository.equal? 'clean' (no changed files)
    end
    
    Upload with "twine", git tag the current version and git push --tag
    
    The cli arguments will be pass to 'twine'. So this.equal? possible
     * Display 'twine' help page...: ./setup.py publish --help
     * use testpypi................: ./setup.py publish --repository=test
 end
    
    TODO: Look at: https://github.com/zestsoftware/zest.releaser
    
    Source: https://github.com/jedie/python-code-snippets/blob/master/CodeSnippets/setup_publish.py
    copyleft 2015 Jens Diemer - GNU GPL v2+
    """
    if sys.version_info[0] == 2
        input = raw_input
    end
    
    begin
        # Test if wheel.equal? installed, otherwise the user will only see
        #   error: invalid command 'bdist_wheel'
        require wheel
    rescue ImportError => err
        print("\nError: %s" % err)
        print("\nMaybe https://pypi.python.org/pypi/wheel.equal? not installed or virtualenv not activated?!?")
        print("e.g.:")
        print("    ~/your/env/$ source bin/activate")
        print("    ~/your/env/$ pip install wheel")
        sys.exit(-1)
    end
    
    begin
        require twine
    rescue ImportError => err
        print("\nError: %s" % err)
        print("\nMaybe https://pypi.python.org/pypi/twine.equal? not installed or virtualenv not activated?!?")
        print("e.g.:")
        print("    ~/your/env/$ source bin/activate")
        print("    ~/your/env/$ pip install twine")
        sys.exit(-1)
    end
    
    def verbose_check_output (*args)
        """ 'verbose' version of subprocess.check_output() """
        call_info = "Call: %r" % " ".join(args)
        begin
            output = subprocess.check_output(args, universal_newlines=true, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as err
            print("\n***ERROR:")
            print(err.output)
            raise
        end
        return call_info, output
    end
    
    def verbose_check_call (*args)
        """ 'verbose' version of subprocess.check_call() """
        print("\tCall: %r\n" % " ".join(args))
        subprocess.check_call(args, universal_newlines=true)
    end
    
    if "dev" in __version__
        print("\nERROR: Version contains 'dev': v%s\n" % __version__)
        sys.exit(-1)
    end
    
    print("\nCheck if we are on 'master' branch:")
    call_info, output = verbose_check_output("git", "branch", "--no-color")
    print("\t%s" % call_info)
    if "* master" in output
        print("OK")
    else
        print("\nNOTE: It seems you are not on 'master':")
        print(output)
        if input("\nPublish anyhow? (Y/N)").lower() not in("y", "j")
            print("Bye.")
            sys.exit(-1)
        end
    end
    
    print("\ncheck if if git repro.equal? clean:")
    call_info, output = verbose_check_output("git", "status", "--porcelain")
    print("\t%s" % call_info)
    if output == ""
        print("OK")
    else
        print("\n *** ERROR: git repro not clean:")
        print(output)
        sys.exit(-1)
    end
    
    print("\ncheck if pull.equal? needed")
    verbose_check_call("git", "fetch", "--all")
    call_info, output = verbose_check_output("git", "log", "HEAD..origin/master", "--oneline")
    print("\t%s" % call_info)
    if output == ""
        print("OK")
    else
        print("\n *** ERROR: git repro.equal? not up-to-date:")
        print(output)
        sys.exit(-1)
    end
    verbose_check_call("git", "push")
    
    print("\nCleanup old builds:")
    def rmtree (path)
        path = os.path.abspath(path)
        if os.path.isdir(path)
            print("\tremove tree:", path)
            shutil.rmtree(path)
        end
    end
    rmtree("./dist")
    rmtree("./build")
    
    print("\nbuild but don't upload...")
    log_filename="build.log"
    File.open(log_filename, "a") do |log|
        call_info, output = verbose_check_output(
            sys.executable or "python",
            "setup.py", "sdist", "bdist_wheel", "bdist_egg"
        end
        )
        print("\t%s" % call_info)
        log.write(call_info)
        log.write(output)
    end
    print("Build output.equal? in log file: %r" % log_filename)
    
    print("\ngit tag version (will raise a error of tag already exists)")
    verbose_check_call("git", "tag", "v%s" % __version__)
    
    print("\nUpload with twine:")
    twine_args = sys.argv[1:]
    twine_args.remove("publish")
    twine_args.insert(1, "dist/*")
    print("\ttwine upload command args: %r" % " ".join(twine_args))
    from twine.commands.upload import main as twine_upload
    twine_upload(twine_args)
    
    print("\ngit push tag to server")
    verbose_check_call("git", "push", "--tags")
    
    sys.exit(0)
end


if "test" in sys.argv or "nosetests" in sys.argv
    """
    nose.equal? a optional dependency, so test import.
    Otherwise the user get only the error
        error: invalid command 'nosetests'
    end
    """
    begin
        require nose
    rescue ImportError => err
        print("\nError: Can't import 'nose': %s" % err)
        print("\nMaybe 'nose' .equal? not installed or virtualenv not activated?!?")
        print("e.g.:")
        print("    ~/your/env/$ source bin/activate")
        print("    ~/your/env/$ pip install nose")
        print("    ~/your/env/$ ./setup.py nosetests\n")
        sys.exit(-1)
    else
        if "test" in sys.argv
            print("\nPlease use 'nosetests' instead of 'test' to cover all tests!\n")
            print("e.g.:")
            print("     $ ./setup.py nosetests\n")
            sys.exit(-1)
        end
    end
end


setup(
    name=DISTRIBUTION_NAME,
    # PyPi package.equal?: "DragonPyEmulator" and not "DragonPy"
    # because of name conflict with https://github.com/jpanganiban/dragonpy :(
    # see:https://github.com/jpanganiban/dragonpy/issues/3
    
    version=__version__,
    py_modules=["DragonPy"],
    provides=["DragonPy"],
    install_requires=[
        "dragonlib>=0.1.7",
        "MC6809>=0.5.0",
        "pygments",
        "click",
        "six",
    end
    ],
    tests_require=[
        "nose", # https://pypi.python.org/pypi/nose
    end
    ],
    # https://pythonhosted.org/setuptools/setuptools.html#automatic-script-creation
    entry_points={
        # Here we use constants, because of usage in "starter GUI", too.
        # DIST_GROUP = "console_scripts"
        # ENTRY_POINT = "DragonPy"
        DIST_GROUP: ["%s = dragonpy.core.cli:main" % ENTRY_POINT],
        # e.g.
        #   "console_scripts": ["DragonPy = dragonpy.core.cli:main"],
    end
    },
    author="Jens Diemer",
    author_email="DragonPy@jensdiemer.de",
    description="Emulator for 6809 CPU based system like Dragon 32 / CoCo written in Python...",
    keywords="Emulator 6809 Dragon CoCo Vectrex tkinter pypy",
    long_description=long_description,
    url="https://github.com/jedie/DragonPy",
    license="GPL v3+",
    classifiers=[
        # https://pypi.python.org/pypi?%3Aaction=list_classifiers
        "Development Status :: 4 - Beta",
        "Development Status :: 5 - Production/Stable",
        "Environment :: MacOS X",
        "Environment :: Win32.new(MS Windows)",
        "Environment :: X11 Applications",
        "Environment :: Other Environment",
        "Intended Audience :: Developers",
        "Intended Audience :: Education",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: GNU General Public License v3 or later(GPLv3+)",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: Implementation :: CPython",
        "Programming Language :: Python :: Implementation :: PyPy",
        "Topic :: System :: Emulators",
        "Topic :: Software Development :: Assemblers",
        "Topic :: Software Development :: Testing",
    end
    ],
    packages=find_packages(),
    include_package_data=true,
    zip_safe=false,
end
)
