/**
 A module with tests to test the compile-time reflection
 */

module unit_threaded.tests.parametrized;

import unit_threaded.attrs;

version(unittest) {

    @(1, 2, 3)
    void testValues(int i) {
        assert(i % 2 != 0);
    }

    @Types!(float, int)
    void testTypes(T)() {
        assert(T.init == 0);
    }
}

@("builtinIntValues")
@Values(2, 3, 4, 5)
unittest {
    import std.conv;
    immutable i = getValue!int;
    assert(i == 3);
}
