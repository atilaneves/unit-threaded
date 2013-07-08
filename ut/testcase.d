module ut.testcase;

import std.stdio;
import std.conv;

struct TestResult {
    immutable bool success;
    immutable string output;
}


class TestCase {
    string getPath() {
        return this.classinfo.name;
    }
    final TestResult run() {
        setup();
        test();
        shutdown();
        return TestResult(!_failed, _output);
    }
    void setup() { }
    void shutdown() { }
    abstract void test();

protected:

    void assertTrue(bool condition, uint line = __LINE__, string file = __FILE__) {
        if(!condition) fail(condition, true, line, file);
    }

    void assertFalse(bool condition, uint line = __LINE__, string file = __FILE__) {
        if(condition) fail(condition, false, line, file);
    }

    void assertEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        if(value != expected) fail(value, expected, line, file);
    }

    void assertNotEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        if(value == expected) fail(value, expected, line, file);
    }


private:
    bool _failed;
    string _output;

    void fail(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        output(value, expected, line, file);
        _failed = true;
    }

    void output(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        _output ~= "    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
            " is not the expected " ~ to!string(expected) ~ "\n";
    }
}

unittest {
}
