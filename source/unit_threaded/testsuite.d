module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.factory: createTestCases;
import std.datetime;
import std.parallelism: taskPool;
import std.algorithm;


/**
 * Only exists because taskPool.amap only works with regular functions,
 * not closures.
 */
auto runTest(TestCase test)
{
    return test();
}

/**
 * Responsible for running tests
 */
struct TestSuite
{
    this(in Options options, in TestData[] testData)
    {
        _options = options;
        _testCases = createTestCases(testData, options.testsToRun);
    }

    /**
     * Runs the tests with the given options.
     * Returns: how long it took to run.
     */
    Duration run()
    {
        auto tests = getTests();
        _stopWatch.start();

        if(_options.multiThreaded)
        {
            _failures = reduce!((a, b) => a ~ b)(_failures,
                                                 taskPool.amap!runTest(tests));
        }
        else
        {
            foreach(test; tests) _failures ~= test();
        }

        handleFailures();

        _stopWatch.stop();
        return cast(Duration)_stopWatch.peek();
    }

    @property ulong numTestsRun() const
    {
        return _testCases.map!(a => a.numTestsRun).reduce!((a, b) => a + b);
    }

    @property ulong numFailures() const pure nothrow
    {
        return _failures.length;
    }

    @property bool passed() const pure nothrow
    {
        return numFailures() == 0;
    }

    @property ulong numTestCases() const pure nothrow
    {
        return _testCases.length;
    }

private:

    const(Options) _options;
    TestCase[] _testCases;
    string[] _failures;
    StopWatch _stopWatch;

    auto getTests()
    {
        auto tests = _testCases;
        if(_options.random)
        {
            import std.random;
            auto generator = Random(_options.seed);
            tests.randomShuffle(generator);
            utWriteln("Running tests in random order. ",
                      "To repeat this run, use --seed ", _options.seed);
        }
        return tests;
    }

    void handleFailures()
    {
        if(_failures) utWriteln("");
        foreach(failure; _failures)
        {
            utWrite("Test ", failure, " ");
            utWriteRed("failed");
            utWriteln(".");
        }
        if(_failures) utWriteln("");
    }
}
