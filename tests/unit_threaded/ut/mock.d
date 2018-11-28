module unit_threaded.ut.mock;


import unit_threaded.mock;
import unit_threaded.asserts;


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
    m.verify.shouldThrowWithMessage("Expected nth 0 call to `foo` did not happen");
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
                       "    tests/unit_threaded/ut/mock.d:123 - Expected nth 0 call to `foobar` did not happen\n");
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
    import unit_threaded.exception: UnitTestException;
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


///
@("mock struct positive")
@safe pure unittest {
    void fun(T)(T t) {
        t.foobar;
    }
    auto m = mockStruct;
    m.expect!"foobar";
    fun(m);
    m.verify;
}


///
@("mock struct values positive")
@safe pure unittest {
    void fun(T)(T t) {
        t.foobar(2, "quux");
    }

    auto m = mockStruct;
    m.expect!"foobar"(2, "quux");
    fun(m);
    m.verify;
}


///
@("struct return value")
@safe pure unittest {

    int fun(T)(T f) {
        return f.timesN(3) * 2;
    }

    auto m = mockStruct(42, 12);
    assert(fun(m) == 84);
    assert(fun(m) == 24);
    assert(fun(m) == 0);
    m.expectCalled!"timesN";
}

///
@("struct expectCalled")
@safe pure unittest {
    void fun(T)(T t) {
        t.foobar(2, "quux");
    }

    auto m = mockStruct;
    fun(m);
    m.expectCalled!"foobar"(2, "quux");
}

///
@("mockStruct different return types for different functions")
@safe pure unittest {
    auto m = mockStruct!(ReturnValues!("length", 5),
                         ReturnValues!("greet", "hello"));
    assert(m.length == 5);
    assert(m.greet("bar") == "hello");
    m.expectCalled!"length";
    m.expectCalled!"greet"("bar");
}

///
@("mockStruct different return types for different functions and multiple return values")
@safe pure unittest {
    auto m = mockStruct!(
        ReturnValues!("length", 5, 3),
        ReturnValues!("greet", "hello", "g'day"),
        ReturnValues!("list", [1, 2, 3]),
    );

    assert(m.length == 5);
    m.expectCalled!"length";
    assert(m.length == 3);
    m.expectCalled!"length";

    assert(m.greet("bar") == "hello");
    m.expectCalled!"greet"("bar");
    assert(m.greet("quux") == "g'day");
    m.expectCalled!"greet"("quux");

    assertEqual(m.list, [1, 2, 3]);
}


///
@("throwStruct default")
@safe pure unittest {
    import std.exception: assertThrown;
    import unit_threaded.exception: UnitTestException;
    auto m = throwStruct;
    assertThrown!UnitTestException(m.foo);
    assertThrown!UnitTestException(m.bar(1, "foo"));
}


@("const mockStruct values")
@safe pure unittest {
    const m = mockStruct(42);
    assertEqual(m.length, 42);
    assertEqual(m.length, 42);
}


@("const mockStruct ReturnValues")
@safe pure unittest {
    const m = mockStruct!(ReturnValues!("length", 42));
    assertEqual(m.length, 42);
    assertEqual(m.length, 42);
}


@("mockReturn")
@safe pure unittest {
    auto m = mockStruct(
        mockReturn!"length"(5, 3),
        mockReturn!"greet"("hello", "g'day"),
        mockReturn!"list"([1, 2, 3]),
    );

    assert(m.length == 5);
    m.expectCalled!"length";
    assertEqual(m.length, 3);
    m.expectCalled!"length";

    assertEqual(m.greet("bar"), "hello");
    m.expectCalled!"greet"("bar");
    assertEqual(m.greet("quux"), "g'day");
    m.expectCalled!"greet"("quux");

    assertEqual(m.list, [1, 2, 3]);
}


@safe pure unittest {

    static struct Cursor {
        enum Kind {
            StructDecl,
            FieldDecl,
        }
    }

    static struct Type {
        enum Kind {
            Int,
            Double,
        }
    }

    const cursor = mockStruct(
        mockReturn!"kind"(Cursor.Kind.StructDecl),
        mockReturn!"spelling"("Foo"),
        mockReturn!"children"(
            [
                mockStruct(mockReturn!("kind")(Cursor.Kind.FieldDecl),
                           mockReturn!"spelling"("i"),
                           mockReturn!("type")(
                               mockStruct(
                                   mockReturn!"kind"(Type.Kind.Int),
                                   mockReturn!"spelling"("int"),
                               )
                           )
                ),
                mockStruct(mockReturn!("kind")(Cursor.Kind.FieldDecl),
                           mockReturn!"spelling"("d"),
                           mockReturn!("type")(
                               mockStruct(
                                   mockReturn!"kind"(Type.Kind.Double),
                                   mockReturn!"spelling"("double"),
                               )
                           )
                ),
            ],
        ),
    );

    assertEqual(cursor.kind, Cursor.Kind.StructDecl);
    assertEqual(cursor.spelling, "Foo");
    assertEqual(cursor.children.length, 2);

    const i = cursor.children[0];
    assertEqual(i.kind, Cursor.Kind.FieldDecl);
    assertEqual(i.spelling, "i");
    assertEqual(i.type.kind, Type.Kind.Int);
    assertEqual(i.type.spelling, "int");

    const d = cursor.children[1];
    assertEqual(d.kind, Cursor.Kind.FieldDecl);
    assertEqual(d.spelling, "d");
    assertEqual(d.type.kind, Type.Kind.Double);
    assertEqual(d.type.spelling, "double");
}
