module unit_threaded.options;

import std.getopt;
import std.stdio;

struct Options {
    immutable bool multiThreaded;
    immutable string[] tests;
    immutable bool debugOutput;
};

/**
 * Parses the command-line args and returns Options
 */
auto getOptions(string[] args) {
    bool single = false;
    bool debugOutput = false;
    getopt(args,
           "single|s", &single, //single-threaded
           "debug|d", &debugOutput); //print debug output
    if(debugOutput) {
        if(!single) {
            stderr.writeln("\n***** Cannot use -d without -s, forcing -s *****\n\n");
        }
        single = true;
    }
    return Options(!single, args[1..$].dup, debugOutput);
}
