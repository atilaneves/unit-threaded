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

    @property ulong numTestsRun() const {
        return _tests.map!(a => a.numTestsRun).reduce!"a+b";
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

    void innerLoop(TestCase test) {
        _failures ~= test();
    }
}
