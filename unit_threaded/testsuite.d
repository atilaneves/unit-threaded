module unit_threaded.testsuite;

import unit_threaded.testcase;
import unit_threaded.writer_thread;
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

    double run(Tid writerTid, in bool multiThreaded = true) {
        _stopWatch.start();

        immutable redirectIo = multiThreaded;

        if(multiThreaded) {
            foreach(test; taskPool.parallel(_tests)) innerLoop(test, writerTid);
        } else {
            foreach(test; _tests) innerLoop(test, writerTid);
        }

        if(_failures) writerTid.send("\n");
        foreach(failure; _failures) {
            writerTid.send(text("Test ", failure, " failed.\n"));
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

    void innerLoop(TestCase test, Tid writerTid) {
        writerTid.send(test.getPath() ~ ":\n");
        immutable result = test();
        if(result.failed) {
            addFailure(test.getPath());
        }
        writerTid.send(result.output);
    }
}
