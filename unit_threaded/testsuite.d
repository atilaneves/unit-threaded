module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.io;
import std.datetime;
import std.parallelism;
import std.concurrency;
import std.stdio;
import std.conv;
import std.algorithm;

/**
 * Responsible for running tests
 */
struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    double run(in bool multiThreaded = true) {
        _stopWatch.start();

        if(multiThreaded) {
            foreach(test; parallel(_tests)) _failures ~= test();
        } else {
            foreach(test; _tests) _failures ~= test();
        }

        if(_failures) utWriteln("");
        foreach(failure; _failures) {
            utWrite("Test ", failure, " ");
            utWriteRed("failed");
            utWriteln(".");
        }
        if(_failures) writeln("");

        _stopWatch.stop();
        return _stopWatch.peek().seconds();
    }

    @property ulong numTestsRun() const {
        return _tests.map!"a.numTestsRun".reduce!"a+b";
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
}
