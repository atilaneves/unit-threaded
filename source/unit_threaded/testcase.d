module unit_threaded.testcase;

import unit_threaded.check;
import unit_threaded.io;
import unit_threaded.reflection: TestData, TestFunction;

import std.exception;
import std.algorithm;


/**
 * Class from which other test cases derive
 */
class TestCase {
    string getPath() const pure nothrow {
        return this.classinfo.name;
    }

    /**
     * Executes the test.
     * Returns: array of failures
     */
    string[] opCall() {
        collectOutput();
        printToScreen();
        return _failed ? [getPath()] : [];
    }

    final auto collectOutput() {
        print(getPath() ~ ":\n");
        try {
            test();
        } catch(UnitTestException ex) {
            fail(ex.msg);
        } catch(Exception ex) {
            fail("\n    " ~ ex.toString() ~ "\n");
        } catch(Throwable t) {
            utFail(t.msg, t.file, t.line);
        }
        if(_failed) print("\n\n");
    }

    void printToScreen() const {
        utWrite(_output);
    }

    abstract void test();
    ulong numTestsRun() const { return 1; }

private:
    bool _failed;
    string _output;

    void fail(in string msg) {
        _failed = true;
        print(msg);
    }

    void print(in string msg) {
        addToOutput(_output, msg);
    }
}


class FunctionTestCase: TestCase {
    this(immutable TestData data) pure nothrow {
        _name = data.name;
        _func = data.testFunction;
    }

    override void test() {
        _func();
    }

    override string getPath() const pure nothrow {
        return _name;
    }

    private string _name;
    private TestFunction _func;
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


class CompositeTestCase: TestCase {
    void add(TestCase t) { _tests ~= t;}

    void opOpAssign(string op : "~")(TestCase t) {
        add(t);
    }

    override string[] opCall() {
        return _tests.map!(a => a()).reduce!((a, b) => a ~ b);
    }

    override void test() { assert(false, "CompositeTestCase.test should never be called"); }

    override ulong numTestsRun() const {
        return _tests.length;
    }

private:

    TestCase[] _tests;
}
