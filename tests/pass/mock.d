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

struct Namespace {
    import std.datetime : Duration;
    class HiddenTypes {
        abstract Duration identity(Duration) pure @safe;
    }
}

@safe pure unittest {
    auto m = mock!(Namespace.HiddenTypes);
    {
        import std.datetime : Duration;
        m.expect!"identity"(Duration.init);
        m.identity(Duration.init);
        m.verify;
    }
}

@("private or protected members") @safe pure unittest {
    interface InterfaceWithProtected {
        bool result();
        protected final void inner(int i) { }
    }

    auto m = mock!InterfaceWithProtected;
}


struct Struct { }

@("default params")
@safe pure unittest {
    interface Interface {
        void write(Struct stream, ulong nbytes = 0LU);
    }

    auto m = mock!Interface;
}
