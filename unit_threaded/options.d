module unit_threaded.options;

import std.getopt;

struct Options {
    immutable bool multiThreaded;
    immutable string[] tests;
};

auto getOptions(string[] args) {
    bool single = false;
    getopt(args, "single|s", &single);
    return Options(!single, args[1..$].dup);
}
