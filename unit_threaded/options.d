module unit_threaded.options;

import std.getopt;

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
    return Options(!single, args[1..$].dup, debugOutput);
}
