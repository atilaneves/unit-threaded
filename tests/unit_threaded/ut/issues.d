module unit_threaded.ut.issues;

import unit_threaded;


@("82")
unittest {

    import std.exception: assertThrown;

    static class A {
        string x;

        override string toString() const {
            return x;
        }
    }

    class B : A {}

    auto actual = new B;
    auto expected = new B;

    actual.x = "foo";
    expected.x = "bar";
    assertThrown(actual.shouldEqual(expected));
}
