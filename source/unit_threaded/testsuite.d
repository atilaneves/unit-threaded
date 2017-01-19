/**
 * This module implements $(D TestSuite), an aggregator for $(D TestCase)
 * objects to run all tests.
 */

module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.factory;
import unit_threaded.reflection;
import std.datetime;
import std.parallelism : taskPool;
import std.algorithm;
import std.conv : text;
import std.array;
import core.runtime;

/*
 * taskPool.amap only works with public functions, not closures.
 */
auto runTest(TestCase test)
{
    return test();
}

/**
 * Responsible for running tests and printing output.
 */
struct TestSuite
{
    package Output output;

    this(in Options options, in TestData[] testData) {
        import unit_threaded.io: WriterThread;
        this(options, testData, WriterThread.get);
    }

    /**
     * Params:
     * options = The options to run tests with.
     * testData = The information about the tests to run.
     */
    this(in Options options, in TestData[] testData, Output output) {
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
        if (!_failures.empty)
            _output.writeln("");
        foreach (failure; _failures) {
            _output.write("Test ", (failure.canFind(" ") ? `"` ~ failure ~ `"` : failure), " ");
            _output.writeRed("failed");
            _output.writeln(".");
        }
        if (!_failures.empty)
            _output.writeln("");
    }

    @property ulong numTestsRun() @trusted const {
        return _testCases.map!(a => a.numTestsRun).reduce!((a, b) => a + b);
    }
}

/**
 * Replace the D runtime's normal unittest block tester. If this is not done,
 * the tests will run twice.
 */
void replaceModuleUnitTester() {
    import core.runtime;

    Runtime.moduleUnitTester = &moduleUnitTester;
}

shared static this() {
    replaceModuleUnitTester();
}

/**
 * Replacement for the usual unittest runner. Since unit_threaded
 * runs the tests itself, the moduleUnitTester doesn't really have to do anything.
 */
private bool moduleUnitTester() {
    //this is so unit-threaded's own tests run
    import std.algorithm;
    foreach(module_; ModuleInfo) {
        if(module_ && module_.unitTest &&
           module_.name.startsWith("unit_threaded") && // we want to run the "normal" unit tests
           //!module_.name.startsWith("unit_threaded.property") && // left here for fast iteration when developing
           !module_.name.startsWith("unit_threaded.tests")) { //but not the ones from the test modules
            version(testing_unit_threaded) {
                import std.stdio: writeln;
                writeln("Running unit-threaded UT for module " ~ module_.name);
            }
            module_.unitTest()();

        }
    }

    return true;
}
