module unit_threaded.mock;

import unit_threaded.should: fail;
import std.traits;
import std.typecons;

version(unittest) {
    import unit_threaded.asserts;
    import unit_threaded.should;
}


alias Identity(alias T) = T;

string implMixinStr(T)() {
    import std.array: join;

    string[] lines;

    foreach(m; __traits(allMembers, T)) {

        alias member = Identity!(__traits(getMember, T, m));

        static if(__traits(isAbstractFunction, member)) {

            enum parameters = Parameters!member.stringof;
            enum returnType = ReturnType!member.stringof;

            static if(is(ReturnType!member == void))
                enum returnDefault = "";
            else
                enum returnDefault = `    return ` ~ returnType ~ ".init;";

            lines ~= `override ` ~ returnType ~ " " ~ m ~ typeAndArgsParens!(Parameters!member) ~ ` {`;
            lines ~= `    called ~= "` ~ m ~ `";`;
            lines ~= `    values ~= tuple` ~ argNamesParens(arity!member) ~ `.to!string;`;
            lines ~= returnDefault;
            lines ~= `}`;
            lines ~= "";
        }
    }

    return lines.join("\n");
}

private string argNamesParens(int N) @safe pure {
    return "(" ~ argNames(N) ~ ")";
}

private string argNames(int N) @safe pure {
    import std.range;
    import std.algorithm;
    import std.conv;
    return iota(N).map!(a => "arg" ~ a.to!string).join(", ");
}

private string typeAndArgsParens(T...)() {
    import std.array;
    import std.conv;
    string[] parts;
    foreach(i, t; T)
        parts ~= T[i].stringof ~ " arg" ~ i.to!string;
    return "(" ~ parts.join(", ") ~ ")";
}


struct Mock(T) {

    private bool verified;
    private string[] expectedFuncs;
    private string[] _expectedValues;
    MockAbstract _mocked;

    alias _mocked this;

    class MockAbstract: T {

        import std.conv: to;

        string[] called;
        string[] values;

        //pragma(msg, implMixinStr!T);
        mixin(implMixinStr!T);
    }

    ~this() pure @safe {
        if(!verified) verify;
    }

    void expect(string func, V...)(V values) {
        import std.conv: to;

        if(_mocked is null) _mocked = new MockAbstract;
        expectedFuncs ~= func;
        static if(V.length > 0)
            _expectedValues ~= tuple(values).to!string;
        else
            _expectedValues ~= "";
    }

    void verify(string file = __FILE__, ulong line = __LINE__) @safe pure {
        import unit_threaded.should: fail;
        import std.conv: to;
        import std.range: repeat, take;
        import std.array: join;

        if(verified)
            fail("Mock already verified", file, line);

        verified = true;

        for(int i = 0; i < expectedFuncs.length; ++i) {

            if(i >= called.length)
                fail("Expected nth " ~ i.to!string ~ " call to " ~ expectedFuncs[i] ~ " did not happen", file, line);

            if(expectedFuncs[i] != called[i])
                fail("Expected nth " ~ i.to!string ~ " call to " ~ expectedFuncs[i] ~ " but got " ~ called[i] ~ " instead", file, line);

            if(_expectedValues[i] != _mocked.values[i] && _expectedValues[i] != "")
                throw new UnitTestException([expectedFuncs[i] ~ " was called with unexpected " ~ _mocked.values[i],
                                             " ".repeat.take(expectedFuncs[i].length + 4).join ~
                                             "instead of the expected " ~ _expectedValues[i]] ,
                                            file, line);
        }
    }
}

auto mock(T)() {
    return Mock!T();
}

@("mock interface positive test no params")
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

@("mock interface positive test with params")
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
        m.expect!"foo"(5, "foobar");
        fun(m);
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(6, "foobar");
        fun(m);
        assertExceptionMsg(m.verify,
                           "    source/unit_threaded/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, \"foobar\")\n"
                           "    source/unit_threaded/mock.d:123 -        instead of the expected Tuple!(int, string)(6, \"foobar\")");
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(5, "quux");
        fun(m);
        assertExceptionMsg(m.verify,
                           "    source/unit_threaded/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, \"foobar\")\n"
                           "    source/unit_threaded/mock.d:123 -        instead of the expected Tuple!(int, string)(5, \"quux\")");
    }
}


@("mock interface negative test")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
    }

    auto m = mock!Foo;
    m.expect!"foo";
    m.verify.shouldThrowWithMessage("Expected nth 0 call to foo did not happen");
}

// can't be in the unit test itself
version(unittest)
private class Class {
    abstract int foo(int, string) @safe pure;
    final int timesTwo(int i) @safe pure nothrow const { return i * 2; }
    int timesThree(int i) @safe pure nothrow const { return i * 3; }
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
