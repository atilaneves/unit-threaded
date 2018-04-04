module unit_threaded.ut.mock;

import unit_threaded.mock;

@("mock interface verify fails")
@safe pure unittest {
    import unit_threaded.asserts;

    interface Foo {
        int foo(int, string) @safe pure;
        void bar() @safe pure;
    }

    int fun(Foo f) {
        return 2 * f.foo(5, "foobar");
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(6, "foobar");
        fun(m);
        assertExceptionMsg(m.verify,
                           `    tests/unit_threaded/ut/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, "foobar")` ~ "\n" ~
                           `    tests/unit_threaded/ut/mock.d:123 -        instead of the expected Tuple!(int, string)(6, "foobar")`);
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(5, "quux");
        fun(m);
        assertExceptionMsg(m.verify,
                           `    tests/unit_threaded/ut/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, "foobar")` ~ "\n" ~
                           `    tests/unit_threaded/ut/mock.d:123 -        instead of the expected Tuple!(int, string)(5, "quux")`);
    }
}

@("mock interface negative test")
@safe pure unittest {
    import unit_threaded.should;

    interface Foo {
        int foo(int, string) @safe pure;
    }

    auto m = mock!Foo;
    m.expect!"foo";
    m.verify.shouldThrowWithMessage("Expected nth 0 call to foo did not happen");
}

// can't be in the unit test itself
private class Class {
    abstract int foo(int, string) @safe pure;
    final int timesTwo(int i) @safe pure nothrow const { return i * 2; }
    int timesThree(int i) @safe pure nothrow const { return i * 3; }
    int timesThreeMutable(int i) @safe pure nothrow { return i * 3; }
}

@("mock class positive test")
@safe pure unittest {

    int fun(Class f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Class;
    m.expect!"foo";
    fun(m);
}


@("mock interface multiple calls")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
        int bar(int) @safe pure;
    }

    void fun(Foo f) {
        f.foo(3, "foo");
        f.bar(5);
        f.foo(4, "quux");
    }

    auto m = mock!Foo;
    m.expect!"foo"(3, "foo");
    m.expect!"bar"(5);
    m.expect!"foo"(4, "quux");
    fun(m);
    m.verify;
}

@("mock struct negative")
@safe pure unittest {
    import unit_threaded.asserts;

    auto m = mockStruct;
    m.expect!"foobar";
    assertExceptionMsg(m.verify,
                       "    tests/unit_threaded/ut/mock.d:123 - Expected nth 0 call to foobar did not happen\n");

}

@("mock struct values negative")
@safe pure unittest {
    import unit_threaded.asserts;

    void fun(T)(T t) {
        t.foobar(2, "quux");
    }

    auto m = mockStruct;
    m.expect!"foobar"(3, "quux");
    fun(m);
    assertExceptionMsg(m.verify,
                       "    tests/unit_threaded/ut/mock.d:123 - foobar was called with unexpected Tuple!(int, string)(2, \"quux\")\n" ~
                       "    tests/unit_threaded/ut/mock.d:123 -           instead of the expected Tuple!(int, string)(3, \"quux\")");
}


@("const(ubyte)[] return type]")
@safe pure unittest {
    interface Interface {
        const(ubyte)[] fun();
    }

    auto m = mock!Interface;
}

@("safe pure nothrow")
@safe pure unittest {
    interface Interface {
        int twice(int i) @safe pure nothrow /*@nogc*/;
    }
    auto m = mock!Interface;
}

@("issue 63")
@safe pure unittest {
    import unit_threaded.should;

    interface InterfaceWithOverloads {
        int func(int) @safe pure;
        int func(string) @safe pure;
    }
    alias ov = Identity!(__traits(allMembers, InterfaceWithOverloads)[0]);
    auto m = mock!InterfaceWithOverloads;
    m.returnValue!(0, "func")(3); // int overload
    m.returnValue!(1, "func")(7); // string overload
    m.expect!"func"("foo");
    m.func("foo").shouldEqual(7);
    m.verify;
}

private class FooException: Exception {
    import std.exception: basicExceptionCtors;
    mixin basicExceptionCtors;
}


@("throwStruct custom")
@safe pure unittest {
    import unit_threaded.should: shouldThrow;

    auto m = throwStruct!FooException;
    m.foo.shouldThrow!FooException;
    m.bar(1, "foo").shouldThrow!FooException;
}


@("throwStruct return value type")
@safe pure unittest {
    import unit_threaded.asserts;
    import unit_threaded.should: UnitTestException;
    auto m = throwStruct!(UnitTestException, int);
    int i;
    assertExceptionMsg(i = m.foo,
                       "    tests/unit_threaded/ut/mock.d:123 - foo was called");
    assertExceptionMsg(i = m.bar,
                       "    tests/unit_threaded/ut/mock.d:123 - bar was called");
}

@("issue 68")
@safe pure unittest {
    import unit_threaded.should;

    int fun(Class f) {
        // f.timesTwo is mocked to return 2, no matter what's passed in
        return f.timesThreeMutable(2);
    }

    auto m = mock!Class;
    m.expect!"timesThreeMutable"(2);
    m.returnValue!("timesThreeMutable")(42);
    fun(m).shouldEqual(42);
}

@("issue69")
unittest {
    import unit_threaded.should;

    static interface InterfaceWithOverloadedFuncs {
        string over();
        string over(string str);
    }

    static class ClassWithOverloadedFuncs {
        string over() { return "oops"; }
        string over(string str) { return "oopsie"; }
    }

    auto iMock = mock!InterfaceWithOverloadedFuncs;
    iMock.returnValue!(0, "over")("bar");
    iMock.returnValue!(1, "over")("baz");
    iMock.over.shouldEqual("bar");
    iMock.over("zing").shouldEqual("baz");

    auto cMock = mock!ClassWithOverloadedFuncs;
    cMock.returnValue!(0, "over")("bar");
    cMock.returnValue!(1, "over")("baz");
    cMock.over.shouldEqual("bar");
    cMock.over("zing").shouldEqual("baz");
}
