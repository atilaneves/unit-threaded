module ut.testsuite;

import ut.testcase;
import ut.writer_thread;
import std.datetime;
import std.parallelism;
import std.concurrency;


struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    double run() {
        _stopWatch.start();

        //spawn writer thread to write to stdout
        auto tid = spawn(&writeInThread);
        //foreach(test; taskPool.parallel(_tests)) {
        foreach(test; _tests) {
            immutable result = test();
            if(result.failed) {
                addFailure(test.getPath());
            }
            tid.send(result.output);
        }

        import std.stdio;
        write("Srsly, all of them should have ended by now\n");

        if(_failures) tid.send("\n\n");
        foreach(failure; _failures) {
            tid.send("Test ", failure, " failed.\n");
        }
        if(_failures) tid.send("\n");
        tid.send(thisTid); //join

        _stopWatch.stop();
        return _stopWatch.peek().seconds();
    }

    void addFailure(string testPath) nothrow {
        _failures ~= testPath;
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


}
