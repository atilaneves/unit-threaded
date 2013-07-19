module unit_threaded.testcase;

import unit_threaded.check;
import std.exception;
import std.string;

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

    final auto opCall() nothrow {
        _output ~= getPrefix();
        check(setup());
        check(test());
        check(shutdown());
        _output ~= "\n";
        if(_failed) _output ~= "\n";
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

    bool check(T = Exception, E)(lazy E expression) nothrow {
        setStatus(collectExceptionMsg!T(expression));
        return !_failed;
    }

    void setStatus(in string msg) nothrow {
        if(msg) {
            _failed = true;
            _output ~= chomp(msg);
        }
    }

    void fail(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) nothrow {
        output(value, expected, line, file);
        _failed = true;
    }

    void output(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) nothrow {
        import std.conv;
        _output ~= "\n    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
            " is not the expected " ~ to!string(expected);
    }
}
