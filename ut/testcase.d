module ut.testcase;

import ut.check;
import std.exception;
import std.string;


class TestCase {
    string getPath() {
        return this.classinfo.name;
    }
    final string run() {
        setup();
        test();
        shutdown();
        return _output;
    }
    void setup() { }
    void shutdown() { }
    abstract void test();

protected:

    bool assertTrue(bool condition, uint line = __LINE__, string file = __FILE__) {
        return check(checkTrue(condition, file, line));
    }

    bool assertFalse(bool condition, uint line = __LINE__, string file = __FILE__) {
        return check(checkFalse(condition, file, line));
    }

    bool assertEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        return check(checkEqual(value, expected, file, line));
    }

    bool assertNotEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        return check(checkNotEqual(value, expected, file, line));
    }


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

unittest {
    class Test: TestCase {
        override void test() {
            assert(assertTrue(true));
            assert(assertFalse(false));
            assert(assertEqual(1, 1));
            assert(assertEqual("foo", "foo"));
            assert(assertEqual(true, true));
            assert(assertEqual(false, false));
            assert(assertEqual(1.0, 1.0));
            assert(assertNotEqual(1, 2));
            assert(assertNotEqual(true, false));
            assert(assertNotEqual(1.0, 2.0));
        }
    }
    auto test = new Test;
    test.test();
}
