module ut.testsuite;

import ut.testcase;
import std.datetime;

struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    double run() {
        import std.stdio;
        _stopWatch.start();

        foreach(test; _tests) {
            write(test.getPath() ~ ":");
            stdout.flush();
            immutable error = test();
            if(error) {
                addFailure(test.getPath());
            }
            writeln(error);
            if(error) writeln();
        }

        if(_failures) writeln("\n");
        foreach(failure; _failures) {
            writeln("Test ", failure, " failed.");
        }
        if(_failures) writeln("");

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
