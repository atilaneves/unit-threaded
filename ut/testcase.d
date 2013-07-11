module ut.testcase;

import ut.check;
import std.exception;
import std.string;


class TestCase {
    string getPath() {
        return this.classinfo.name;
    }

    final string opCall() {
        setup();
        check(test());
        shutdown();
        return _output;
    }

    void setup() { }
    void shutdown() { }
    abstract void test();

private:
    bool _failed;
    string _output;

    bool check(E)(lazy E expression) {
        setStatus(collectExceptionMsg(expression));
        return !_failed;
    }

    void setStatus(in string msg) {
        if(msg) {
            _failed = true;
            _output ~= chomp(msg);
        }
    }

    void fail(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        output(value, expected, line, file);
        _failed = true;
    }

    void output(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        import std.conv;
        _output ~= "\n    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
            " is not the expected " ~ to!string(expected);
    }
}
