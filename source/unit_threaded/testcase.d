module unit_threaded.testcase;

import unit_threaded.check;
import unit_threaded.io;

import std.exception;
import std.string;
import std.conv;
import std.algorithm;

struct TestResult {
    int failures;
    string output;
}

/**
 * Class from which other test cases derive
 */
class TestCase {
    string getPath() const pure nothrow {
        return this.classinfo.name;
    }

    string[] opCall() {
        collectOutput();
        printToScreen();
        return _failed ? [getPath()] : [];
    }

    final auto collectOutput() {
        print(getPath() ~ ":\n");
        check(setup());
        check(test());
        check(shutdown());
        if(_failed) print("\n\n");
    }

    void printToScreen() const {
        utWrite(_output);
    }

    void setup() { } ///override to run before test()
    void shutdown() { } ///override to run after test()
    abstract void test();
    ulong numTestsRun() const { return 1; }

private:
    bool _failed;
    string _output;

    bool check(E)(lazy E expression) {
        try {
            expression();
        } catch(UnitTestException ex) {
            fail(ex.msg);
        } catch(Exception ex) {
            fail("\n    " ~ ex.toString() ~ "\n");
        }

        return !_failed;
    }

    void fail(in string msg) {
        _failed = true;
        print(msg);
    }

    void print(in string msg) {
        addToOutput(_output, msg);
    }
}

class CompositeTestCase: TestCase {
    void add(TestCase t) { _tests ~= t;}

    void opOpAssign(string op : "~")(TestCase t) {
        add(t);
    }
    override string[] opCall() {
        return _tests.map!"a()".reduce!"a ~ b";
    }

    override void test() { assert(false, "CompositeTestCase.test should never be called"); }

    override ulong numTestsRun() const {
        return _tests.length;
    }

private:

    TestCase[] _tests;
}


class ShouldFailTestCase: TestCase {
    this(TestCase testCase) {
        this.testCase = testCase;
    }

    override string getPath() const pure nothrow {
        return this.testCase.getPath;
    }

    override void test() {
        const ex = collectException!Exception(testCase.test());
        if(ex is null) {
            throw new Exception("Test " ~ testCase.getPath() ~ " was expected to fail but did not");
        }
    }

private:

    TestCase testCase;
}
