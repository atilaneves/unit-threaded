dtest
=============

###**Warning**: With dmd 2.064.2 on Linux 64-bit this code might crash
**I'm waiting on the bug fix but right now I'm downgrading
to dmd 2.063 to be able to use this library. On Windows it's ok.**

Utility using [unit-threaded](https://github.com/atilaneves/unit-threaded)
to run all unit tests in a list of directories. This was written because,
although [unit-threaded](https://github.com/atilaneves/unit-threaded) can
scan and run all unit tests in a given set of modules, those modules need
to be manually specified, which can be tedious. The reason for that is
that D packages are just directories and the compiler can't
read the filesystem at compile-time, so this executable does that
to write a D source file which it runs using `rdmd`.

This means `rdmd` must be installed for this program to work.

    Usage: dtest [options] [test1] [test2]...
    Options:  
        -h/--help: help  
        -t/--test: add a test directory to the list. If no test directories  
        are specified, then the default list is ["tests"]  
        -u/--unit_threaded: directory location of the unit_threaded library  
        -d/--debug: print debug information  
        -I: extra include directories to specify to rdmd  
        -f/--file: file name to write to  
        -s/--single: run the tests in one thread  
        -d/--debug: print debugging information from the tests  
        -l/--list: list all tests but do not run them  
  
    This will run all unit tests encountered in the given directories
    (see -t option). It does this by scanning them and writing a D source
    file that imports all of them then running that source file with rdmd.
    By default the source file is a randomly named temporary file but that
    can be changed with the -f option. If the unit_threaded library is not
    in the default search paths then it must be specified with the -u option.
    If any command-line arguments exist they will be forwarded to the
    unit_threaded library and used as the names of the tests to run. If
    none are specified, all of them are run.

    To run all tests located in a directory called "tests":  

    dtest -u<PATH_TO_UNIT_THREADED>  

    To run all tests in dir1, dir2, etc.:  

    dtest -u<PATH_TO_UNIT_THREADED> -t dir1 -t dir2...  

    To run tests foo and bar in directory mydir:  

    dtest -u<PATH_TO_UNIT_THREADED> -t mydir mydir.foo mydir.bar

