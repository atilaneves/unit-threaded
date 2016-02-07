/**
 * This module implements $(D TestSuite), an aggregator for $(D TestCase)
 * objects to run all tests.
 */

module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.factory;
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
    /**
     * Params:
     * options = The options to run tests with.
     * testData = The information about the tests to run.
     */
    this(in Options options, in TestData[] testData) {
        _options = options;
        _testData = testData;
        _testCases = createTestCases(testData, options.testsToRun);
        WriterThread.start;
    }

    ~this() {
        WriterThread.get.join;
    }

    /**
     * Runs all test cases.
     * Returns: true if no test failed, false otherwise.
     */
    bool run() {
        if (!_testCases.length) {
            utWritelnRed("Error! No tests to run for args: ");
            utWriteln(_options.testsToRun);
            return false;
        }

        immutable elapsed = doRun();

        if (!numTestsRun) {
            utWriteln("Did not run any tests!!!");
            return false;
        }

        utWriteln("\nTime taken: ", elapsed);
        utWrite(numTestsRun, " test(s) run, ");
        const failuresStr = text(_failures.length, " failed");
        if (_failures.length) {
            utWriteRed(failuresStr);
        } else {
            utWrite(failuresStr);
        }

        void printAbout(string attr)(in string msg) {
            const num = _testData.filter!(a => mixin("a. " ~ attr)).count;
            if (num) {
                utWrite(", ");
                utWriteYellow(num, " " ~ msg);
            }
        }

        printAbout!"hidden"("hidden");
        printAbout!"shouldFail"("failing as expected");

        utWriteln(".\n");

        if (_failures.length) {
            utWritelnRed("Unit tests failed!\n");
            return false; //oops
        }

        utWritelnGreen("OK!\n");

        return true;
    }

private:

    const(Options) _options;
    const(TestData)[] _testData;
    TestCase[] _testCases;
    string[] _failures;
    StopWatch _stopWatch;

    /**
     * Runs the tests with the given options.
     * Returns: how long it took to run.
     */
    Duration doRun() {
        auto tests = getTests();
        _stopWatch.start();

        if (_options.multiThreaded) {
            _failures = reduce!((a, b) => a ~ b)(_failures, taskPool.amap!runTest(tests));
        } else {
            foreach (test; tests)
                _failures ~= test();
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
            utWriteln("Running tests in random order. ",
                "To repeat this run, use --seed ", _options.seed);
        }
        return tests;
    }

    void handleFailures() const {
        if (!_failures.empty)
            utWriteln("");
        foreach (failure; _failures) {
            utWrite("Test ", failure, " ");
            utWriteRed("failed");
            utWriteln(".");
        }
        if (!_failures.empty)
            utWriteln("");
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
    foreach(module_; ModuleInfo) {
        if(module_ && module_.unitTest) {
            if(startsWith(module_.name, "unit_threaded.")) {
                module_.unitTest()();
            }
        }
    }

    return true;
}
