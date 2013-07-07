import std.stdio;
import std.conv;

struct TestResult {
    immutable bool success;
    immutable string output;
}


class TestCase {
    final TestResult run() {
        setup();
        test();
        shutdown();
        return TestResult(!_failed, _output);
    }
    void setup() { }
    void shutdown() { }
    abstract void test();
    void print(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        _output ~= "    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
            " is not the expected " ~ to!string(expected) ~ "\n";
    }

  private:
    bool _failed;
    string _output;
}

unittest {
}
