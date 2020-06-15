/**
   Run-time options.
 */
module unit_threaded.runner.options;


///
struct Options {
    bool multiThreaded;
    string[] testsToRun;
    bool debugOutput;
    bool list;
    bool exit;
    bool forceEscCodes;
    bool random;
    uint seed;
    bool stackTraces;
    bool showChrono;
    bool quiet;
}

/**
 * Parses the command-line args and returns Options
 */
auto getOptions(string[] args) {

    import std.stdio: writeln;
    import std.random: unpredictableSeed;
    import std.getopt: getopt, defaultGetoptPrinter;

    bool single;
    bool debugOutput;
    bool help;
    bool list;
    bool forceEscCodes;
    bool random;
    uint seed = unpredictableSeed;
    bool stackTraces;
    bool showChrono;
    bool quiet;

    auto helpInfo =
        getopt(args,
               "single|s", "Run in one thread", &single,
               "debug|d", "Print debug output", &debugOutput,
               "esccodes|e", "force ANSI escape codes even for !isatty", &forceEscCodes,
               "list|l", "List available tests", &list,
               "random|r", "Run tests in random order (in one thread)", &random,
               "seed", "Set the seed for the random order execution", &seed,
               "trace|t", "enable stack traces", &stackTraces,
               "chrono|c", "Print execution time per test", &showChrono,
               "q|quiet", "Only print information about failing tests", &quiet,
        );

    if(helpInfo.helpWanted) {
        help = true;
        defaultGetoptPrinter("Usage: <progname> <options> <tests>...", helpInfo.options);
    }

    if(random) {
        if(!single) writeln("-r implies -s, running in a single thread\n");
        single = true;
    }

    version(unitUnthreaded)
        single = true;

    immutable exit =  help || list;
    return Options(!single, args[1..$], debugOutput, list, exit, forceEscCodes,
                   random, seed, stackTraces, showChrono, quiet);
}
