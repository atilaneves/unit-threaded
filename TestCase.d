class TestCase {
    abstract void test();
    void setup() { }
    void shutdown() { }
    void run() {
        setup();
        test();
        shutdown();
    }
}

unittest {
    class FooCase: TestCase {
        override void test() {
            throw new Exception("foo!");
        }
    }
    auto foo = new FooCase;
    foo.run();
}
