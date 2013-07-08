module ut.testsuite;

import ut.testcase;
import std.stdio;

struct TestSuite {
    this(TestCase[] tests) {
        _tests = tests;
    }

    double run() {
        foreach(TestCase test; _tests) {
            immutable result = test.run();
            if(!result.success) {
                addFailure(test.getPath());
            }
            write(test.getPath() ~ ":\n" ~ result.output ~ "\n");
        }

        foreach(const ref string failure; _failures) {
            writeln("Test ", failure, " failed.");
        }

        return 0; //TODO: return elapsed time
    }

    void addFailure(string testPath) {
        _failures ~= testPath;
    }

    ulong getNumTestsRun() {
        return _tests.length;
    }

    ulong getNumFailures() {
        return _failures.length;
    }

private:
    TestCase[] _tests;
    string[] _failures;
}
