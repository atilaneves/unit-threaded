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
        foreach(TestCase test; _tests) {
            immutable result = test.run();
            if(!result.success) {
                addFailure(test.getPath());
            }
            writeln(test.getPath() ~ ":\n" ~ result.output);
        }

        foreach(const ref string failure; _failures) {
            writeln("Test ", failure, " failed.");
        }

        _stopWatch.stop();
        return _stopWatch.peek().seconds();
    }

    void addFailure(string testPath) {
        _failures ~= testPath;
    }

    @property ulong numTestsRun() {
        return _tests.length;
    }

    @property ulong numFailures() {
        return _failures.length;
    }

    @property bool passed() {
        return numFailures() == 0;
    }

private:
    TestCase[] _tests;
    string[] _failures;
    StopWatch _stopWatch;
}
