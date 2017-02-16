module tests.pass.mock;

import unit_threaded;

@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
        void bar() @safe pure;
    }

    int fun(Foo f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Foo;
    m.expect!"foo";
    fun(m);
}


@safe pure unittest {
    auto m = mockStruct;
    m.expect!"foo"(2);
    generic(m);
    m.verify;
}

@safe pure unittest {
    auto m = mockStruct;
    generic(m);
    m.expectCalled!"foo"(2);
}

void generic(T)(auto ref T thing) {
    thing.foo(2);
}
