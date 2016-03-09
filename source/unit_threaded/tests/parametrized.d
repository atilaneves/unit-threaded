/**
 A module with tests to test the compile-time reflection
 */

module unit_threaded.tests.parametrized;

version(unittest) {
    import unit_threaded;

    @(1, 2, 3)
    void testValues(int i) {
        assert(i % 2 != 0);
    }

    @Types!(int, float)
    void testTypes(T)() {
        assert(T.init == 0);
    }
}
