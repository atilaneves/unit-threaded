module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import unit_threaded.options;
import std.datetime;
import std.parallelism: taskPool;
import std.concurrency;
import std.stdio;
import std.conv;
import std.algorithm;


auto runTest(TestCase test) {
    return test();
}

/**
 * Responsible for running tests
 */
struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    /**
     * Runs the tests with the given options.
     * Returns: how long it took to run.
     */
    Duration run(in Options options) {
        auto tests = getTests(options);
        _stopWatch.start();

        if(options.multiThreaded) {
            _failures = reduce!((a, b) => a ~ b)(_failures, taskPool.amap!runTest(tests));
        } else {
            foreach(test; tests) _failures ~= test();
        }

        handleFailures();

        _stopWatch.stop();
        return cast(Duration)_stopWatch.peek();
    }

    @property ulong numTestsRun() const {
        return _tests.map!(a => a.numTestsRun).reduce!((a, b) => a + b);
    }

    @property ulong numFailures() const pure nothrow {
        return _failures.length;
    }

    @property bool passed() const pure nothrow {
        return numFailures() == 0;
    }

private:

    TestCase[] _tests;
    string[] _failures;
    StopWatch _stopWatch;

    auto getTests(in Options options) {
        auto tests = _tests;
        if(options.random) {
            import std.random;
            auto generator = Random(options.seed);
            tests.randomShuffle(generator);
            utWriteln("Running tests in random order. To repeat this run, use --seed ", options.seed);
        }
        return tests;
    }

    void handleFailures() {
        if(_failures) utWriteln("");
        foreach(failure; _failures) {
            utWrite("Test ", failure, " ");
            utWriteRed("failed");
            utWriteln(".");
        }
        if(_failures) writeln("");
    }
}
