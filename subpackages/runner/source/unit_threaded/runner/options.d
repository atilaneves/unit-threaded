/**
   Run-time options.
 */
module unit_threaded.runner.options;


///
struct Options {
    size_t numThreads;
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

    this(string[] args) @trusted scope {
        import std.stdio: writeln;
        import std.getopt: getopt, defaultGetoptPrinter;
        import std.parallelism: totalCPUs;

        bool single;
        bool help;

        auto helpInfo =
            getopt(args,
                   "single|s", "Run in one thread", &single,
                   "jobs|j", "Number of parallel test threads. Defaults to the number of logical CPU cores.", &numThreads,
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

        testsToRun = args[1 .. $];

        if(random) {
            if(!single) writeln("-r implies -s, running in a single thread\n");
            single = true;
        }

        version(unitUnthreaded)
            single = true;

        if (single)
            numThreads = 1; // let -s override -j

        if (numThreads == 0)
            numThreads = totalCPUs;

        exit =  help || list;
    }
}
