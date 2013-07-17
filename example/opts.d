module example.opts;

import std.getopt;

struct Options {
    immutable bool multiThreaded;
    immutable string[] args;
};

auto getOptions(string[] args) {
    bool single = false;
    getopt(args, "single|s", &single);
    return Options(!single, args.dup);
}
