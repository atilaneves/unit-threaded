module unit_threaded.options;

import std.getopt;
import std.stdio;

struct Options {
    bool multiThreaded;
    string[] tests;
    bool debugOutput;
    bool list;
    bool exit;
    bool forceEscCodes;
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
    getopt(args,
           "single|s", &single, //single-threaded
           "debug|d", &debugOutput, //print debug output
           "esccodes|e", &forceEscCodes,
           "help|h", &help,
           "list|l", &list);
    if(help) {
        writeln("Usage: <progname> <options> <tests>...\n",
                "Options: \n",
                "   -h: help\n"
                "   -s: single-threaded\n",
                "   -l: list tests\n",
                "   -d: enable debug output\n",
                "   -e: force ANSI escape codes even for !isatty\n",
            );
    }

    if(debugOutput) {
        if(!single) {
            stderr.writeln("\n***** Cannot use -d without -s, forcing -s *****\n\n");
        }
        single = true;
    }
    immutable exit =  help || list;
    return Options(!single, args[1..$], debugOutput, list, exit, forceEscCodes);
}
