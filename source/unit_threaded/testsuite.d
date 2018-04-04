/**
 * This module implements $(D TestSuite), an aggregator for $(D TestCase)
 * objects to run all tests.
 */

module unit_threaded.testsuite;

import unit_threaded.from;

/*
 * taskPool.amap only works with public functions, not closures.
 */
auto runTest(from!"unit_threaded.testcase".TestCase test)
{
    return test();
}

/**
 * Responsible for running tests and printing output.
 */
struct TestSuite
{
    import unit_threaded.io: Output;
    import unit_threaded.options: Options;
    import unit_threaded.reflection: TestData;
    import unit_threaded.testcase: TestCase;
    import std.datetime: Duration;
    static if(__VERSION__ >= 2077)
        import std.datetime.stopwatch: StopWatch;
    else
        import std.datetime: StopWatch;

    this(in Options options, in TestData[] testData) {
        import unit_threaded.io: WriterThread;
        this(options, testData, WriterThread.get);
    }

    /**
     * Params:
     * options = The options to run tests with.
     * testData = The information about the tests to run.
     * output = Where to send text output.
     */
    this(in Options options, in TestData[] testData, Output output) {
        import unit_threaded.factory: createTestCases;

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

        import unit_threaded.io: writelnRed, writeln, writeRed, write, writeYellow, writelnGreen;
        import std.algorithm: filter, count;
        import std.conv: text;

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
            const total = numTestsWithAttr!"shouldFail";
            ulong num = total;

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
     * Runs the tests with the given options.
     * Returns: how long it took to run.
     */
    Duration doRun() {

        import std.algorithm: reduce;
        import std.parallelism: taskPool;

        auto tests = getTests();

        if(_options.showChrono)
            foreach(test; tests)
                test.showChrono;

        _stopWatch.start();

        if (_options.multiThreaded) {
            _failures = reduce!((a, b) => a ~ b)(_failures, taskPool.amap!runTest(tests));
        } else {
            foreach (test; tests) {
                _failures ~= test();
            }
        }

        handleFailures();

        _stopWatch.stop();
        return cast(Duration) _stopWatch.peek();
    }

    auto getTests() {
        import unit_threaded.io: writeln;

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
        import unit_threaded.io: writeln, writeRed, write;
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

/**
 * Replace the D runtime's normal unittest block tester. If this is not done,
 * the tests will run twice.
 */
void replaceModuleUnitTester() {
    import core.runtime: Runtime;
    Runtime.moduleUnitTester = &moduleUnitTester;
}

version(unitThreadedLight) {

    shared static this() {
        import std.algorithm: canFind;
        import std.parallelism: parallel;
        import core.runtime: Runtime;

        Runtime.moduleUnitTester = () {

            // ModuleInfo has opApply, can't use parallel on that so we collect
            // all the modules with unit tests first
            ModuleInfo*[] modules;
            foreach(module_; ModuleInfo) {
                if(module_ && module_.unitTest)
                    modules ~= module_;
            }

            version(unitUnthreaded)
                enum singleThreaded = true;
            else
                const singleThreaded = Runtime.args.canFind("-s") || Runtime.args.canFind("--single");

            if(singleThreaded)
                foreach(module_; modules)
                    module_.unitTest()();
             else
                foreach(module_; modules.parallel)
                    module_.unitTest()();

            return true;
        };
    }

} else {
    shared static this() {
        replaceModuleUnitTester;
    }
}

/**
 * Replacement for the usual unittest runner. Since unit_threaded
 * runs the tests itself, the moduleUnitTester doesn't really have to do anything.
 */
private bool moduleUnitTester() {
    //this is so unit-threaded's own tests run
    import std.algorithm: startsWith;
    foreach(module_; ModuleInfo) {
        if(module_ && module_.unitTest &&
           module_.name.startsWith("unit_threaded") && // we want to run the "normal" unit tests
           //!module_.name.startsWith("unit_threaded.property") && // left here for fast iteration when developing
           !module_.name.startsWith("unit_threaded.ut.modules")) { //but not the ones from the test modules
            version(testing_unit_threaded) {
                import std.stdio: writeln;
                writeln("Running unit-threaded UT for module " ~ module_.name);
            }
            module_.unitTest()();

        }
    }

    return true;
}
