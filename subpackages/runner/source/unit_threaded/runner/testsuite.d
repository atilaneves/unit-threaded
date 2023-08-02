/**
 * This module implements $(D TestSuite), an aggregator for $(D TestCase)
 * objects to run all tests.
 */

module unit_threaded.runner.testsuite;

import unit_threaded.from;

/*
 * taskPool.amap only works with public functions, not closures.
 */
auto runTest(from!"unit_threaded.runner.testcase".TestCase test)
{
    return test();
}

/**
 * Responsible for running tests and printing output.
 */
struct TestSuite
{
    import unit_threaded.runner.io: Output;
    import unit_threaded.runner.options: Options;
    import unit_threaded.runner.reflection: TestData;
    import unit_threaded.runner.testcase: TestCase;
    import std.datetime: Duration;
    static if(__VERSION__ >= 2077)
        import std.datetime.stopwatch: StopWatch;
    else
        import std.datetime: StopWatch;

    /**
     * Params:
     * options = The options to run tests with.
     * testData = The information about the tests to run.
     */
    this(in Options options, const(TestData)[] testData) {
        import unit_threaded.runner.io: WriterThread;
        this(options, testData, WriterThread.get);
    }

    /**
     * Params:
     * options = The options to run tests with.
     * testData = The information about the tests to run.
     * output = Where to send text output.
     */
    this(in Options options, const(TestData)[] testData, Output output) {
        import unit_threaded.runner.factory: createTestCases;

        _options = options;
        _testData = testData;
        _output = output;
        _testCases = createTestCases(testData, options.testsToRun);
    }

    /**
     * Runs all test cases.
     * Returns: true if no test failed, false otherwise.
     */
    bool run() {

        import unit_threaded.runner.io: writelnRed, writeln, writeRed, write, writeYellow, writelnGreen;
        import std.algorithm: filter, count;
        import std.conv: text;

        if (!_testData.length) {
            _output.writeln("No tests to run");
            _output.writelnGreen("OK!\n");
            return true;
        }

        if (!_testCases.length) {
            _output.writelnRed("Error! No tests to run for args: ");
            _output.writeln(_options.testsToRun);
            return false;
        }

        immutable elapsed = doRun();

        if (!numTestsRun) {
            _output.writeln("Did not run any tests!!!");
            return false;
        }

        _output.writeln("\nTime taken: ", elapsed);
        _output.write(numTestsRun, " test(s) run, ");
        const failuresStr = text(_failures.length, " failed");
        if (_failures.length) {
            _output.writeRed(failuresStr);
        } else {
            _output.write(failuresStr);
        }

        ulong numTestsWithAttr(string attr)() {
           return _testData.filter!(a => mixin("a. " ~ attr)).count;
        }

        void printHidden() {
            const num = numTestsWithAttr!"hidden";
            if(!num) return;
            _output.write(", ");
            _output.writeYellow(num, " ", "hidden");
        }

        void printShouldFail() {
            const total = _testCases.filter!(a => a.shouldFail).count;
            long num = total;

            foreach(f; _failures) {
                const data = _testData.filter!(a => a.getPath == f).front;
                if(data.shouldFail) --num;
            }

            if(!total) return;
            _output.write(", ");
            _output.writeYellow(num, "/", total, " ", "failing as expected");
        }

        printHidden();
        printShouldFail();

        _output.writeln(".\n");

        if(_options.random)
            _output.writeln("Tests were run in random order. To repeat this run, use --seed ", _options.seed, "\n");

        if (_failures.length) {
            _output.writelnRed("Tests failed!\n");
            return false; //oops
        }

        _output.writelnGreen("OK!\n");

        return true;
    }

private:

    const(Options) _options;
    const(TestData)[] _testData;
    TestCase[] _testCases;
    string[] _failures;
    StopWatch _stopWatch;
    Output _output;

    /**
     * Runs the tests.
     * Returns: how long it took to run.
     */
    Duration doRun() {

        import std.algorithm: reduce;
        import std.parallelism: TaskPool;

        auto tests = getTests();

        if(_options.showChrono)
            foreach(test; tests)
                test.showChrono;

        if(_options.quiet)
            foreach(test; tests)
                test.quiet;

        _stopWatch.start();

        if (_options.multiThreaded) {
            // use a dedicated task pool with non-daemon worker threads
            auto taskPool = new TaskPool(_options.numJobs);
            _failures = reduce!((a, b) => a ~ b)(_failures, taskPool.amap!runTest(tests));
            taskPool.finish(/*blocking=*/false);
        } else {
            foreach (test; tests) {
                _failures ~= test();
            }
        }

        version(Windows) {
            // spawned child processes etc. may have tampered with the console,
            // try to re-enable the ANSI escape codes for colors
            import unit_threaded.runner.io: tryEnableEscapeCodes;
            tryEnableEscapeCodes();
        }

        handleFailures();

        _stopWatch.stop();
        return cast(Duration) _stopWatch.peek();
    }

    auto getTests() {
        import unit_threaded.runner.io: writeln;

        auto tests = _testCases.dup;

        if (_options.random) {
            import std.random;

            auto generator = Random(_options.seed);
            tests.randomShuffle(generator);
            _output.writeln("Running tests in random order. ",
                "To repeat this run, use --seed ", _options.seed);
        }

        return tests;
    }

    void handleFailures() {
        import unit_threaded.runner.io: writeln, writeRed, write;
        import std.array: empty;
        import std.algorithm: canFind;

        if (!_failures.empty)
            _output.writeln("");
        foreach (failure; _failures) {
            _output.write("Test ", (failure.canFind(" ") ? `'` ~ failure ~ `'` : failure), " ");
            _output.writeRed("failed");
            _output.writeln(".");
        }
        if (!_failures.empty)
            _output.writeln("");
    }

    @property ulong numTestsRun() @trusted const {
        import std.algorithm: map, reduce;
        return _testCases.map!(a => a.numTestsRun).reduce!((a, b) => a + b);
    }
}
