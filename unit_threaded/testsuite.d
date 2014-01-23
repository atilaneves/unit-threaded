module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import std.datetime;
import std.parallelism;
import std.concurrency;
import std.stdio;
import std.conv;

/**
 * Responsible for running tests
 */
struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    double run(in bool multiThreaded = true) {
        _stopWatch.start();

        immutable redirectIo = multiThreaded;

        if(multiThreaded) {
            foreach(test; taskPool.parallel(_tests)) innerLoop(test);
        } else {
            foreach(test; _tests) innerLoop(test);
        }

        if(_failures) utWriteln("");
        foreach(failure; _failures) {
            utWriteln("Test ", failure, " failed.");
        }
        if(_failures) writeln("");

        _stopWatch.stop();
        return _stopWatch.peek().seconds();
    }

    @property ulong numTestsRun() const pure nothrow {
        return _tests.length;
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

    void addFailure(in string testPath) nothrow {
        _failures ~= testPath;
    }

    void innerLoop(TestCase test) {
        immutable result = test();
        if(result.failed) {
            addFailure(test.getPath());
        }
        utWrite(result.output);
    }
}
