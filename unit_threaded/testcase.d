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

    final auto opCall() {
        print(getPath() ~ ":\n");
        check(setup());
        check(test());
        check(shutdown());
        if(_failed) print("\n\n");
        return TestResult(_failed, _output);
    }

    void setup() { } ///override to run before test()
    void shutdown() { } ///override to run after test()
    abstract void test();

private:
    bool _failed;
    string _output;

    bool check(T = Exception, E)(lazy E expression) {
        setStatus(collectExceptionMsg!T(expression));
        return !_failed;
    }

    void setStatus(in string msg) {
        if(msg) {
            _failed = true;
            print(chomp(msg));
        }
    }

    void print(in string msg) {
        addToOutput(_output, msg);
    }
}
