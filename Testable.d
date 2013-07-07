interface Testable {
    void test();
    void setup();
    void shutdown();
    final void run() {
        setup();
        test();
        shutdown();
    }
}
