module unit_threaded.options;

import std.getopt;
import std.stdio;
import std.random;
import std.exception;


struct Options {
    bool multiThreaded;
    string[] testsToRun;
    bool debugOutput;
    bool list;
    bool exit;
    bool forceEscCodes;
    bool random;
    uint seed;
}

/**
 * Parses the command-line args and returns Options
 */
auto getOptions(string[] args) {
    bool single;
    bool debugOutput;
    bool help;
    bool list;
    bool forceEscCodes;
    bool random;
    uint seed = unpredictableSeed;

    getopt(args,
           "single|s", &single, //single-threaded
           "debug|d", &debugOutput, //print debug output
           "esccodes|e", &forceEscCodes,
           "help|h", &help,
           "list|l", &list,
           "random|r", &random,
           "seed", &seed,
        );

    if(help) {
        writeln("Usage: <progname> <options> <tests>...\n",
                "Options: \n",
                "  -h/--help: help\n"
                "  -s/--single: single-threaded\n",
                "  -l/--list: list tests\n",
                "  -d/--debug: enable debug output\n",
                "  -e/--esccodes: force ANSI escape codes even for !isatty\n",
                "  -r/--random: run tests in random order\n",
                "  --seed: set the seed for the random order\n",
            );
    }

    if(debugOutput) {
        if(!single) {
            writeln("-d implies -s, running in a single thread\n");
        }
        single = true;
    }

    if(random) {
        if(!single) writeln("-r implies -s, running in a single thread\n");
        single = true;
    }

    immutable exit =  help || list;
    return Options(!single, args[1..$], debugOutput, list, exit, forceEscCodes,
                   random, seed);
}
