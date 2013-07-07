import std.stdio;

class TestCase {
    abstract void test();
    void setup() { }
    void shutdown() { }
    void run() {
        setup();
        test();
        shutdown();
    }
    void print(T)(T value, T expected, uint line = __LINE__, string file = __FILE__) {
        writeln("    ", file, ":", line, " - Value ", value, " is not the expected ", expected);
    }
}

unittest {
}
