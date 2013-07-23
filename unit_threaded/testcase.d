module unit_threaded.testcase;

import unit_threaded.check;
import unit_threaded.io;

import std.exception;
import std.string;
import std.conv;

struct TestResult {
    immutable bool failed;
    immutable string output;
}

/**
 * Class from which other test cases derive
 */
class TestCase {
    string getPath() const pure nothrow {
        return this.classinfo.name;
    }

    final auto opCall()  {
        addToOutput(_output, getPrefix());
        check(setup());
        check(test());
        check(shutdown());
        addToOutput(_output, "\n");
        if(_failed) addToOutput(_output, "\n");
        return TestResult(_failed, _output);
    }

    void setup() { } ///override to run before test()
    void shutdown() { } ///override to run after test()
    abstract void test();

private:
    bool _failed;
    string _output;

    string getPrefix() const pure nothrow {
        return getPath() ~ ":";
    }

    bool check(T = Exception, E)(lazy E expression) {
        setStatus(collectExceptionMsg!T(expression));
        return !_failed;
    }

    void setStatus(in string msg) {
        if(msg) {
            _failed = true;
            addToOutput(_output, chomp(msg));
        }
    }
}
