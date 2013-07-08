module ut.testcase;


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

    bool assertTrue(bool condition, uint line = __LINE__, string file = __FILE__) {
        if(!condition) fail(condition, true, line, file);
        return !_failed;
    }

    bool assertFalse(bool condition, uint line = __LINE__, string file = __FILE__) {
        if(condition) fail(condition, false, line, file);
        return !_failed;
    }

    bool assertEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        if(value != expected) fail(value, expected, line, file);
        return !_failed;
    }

    bool assertNotEqual(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        if(value == expected) fail(value, expected, line, file);
        return !_failed;
    }


private:
    bool _failed;
    string _output;

    void fail(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        output(value, expected, line, file);
        _failed = true;
    }

    void output(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        import std.conv;
        _output ~= "    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
            " is not the expected " ~ to!string(expected) ~ "\n";
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
