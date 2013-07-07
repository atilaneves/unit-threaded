import std.stdio;
import Testable;

class TestCase: Testable {
    void setup() { }
    void shutdown() { }
    abstract void test();
    void print(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        writeln("    ", file, ":", line, " - Value ", value, " is not the expected ", expected);
    }
}

unittest {
}
