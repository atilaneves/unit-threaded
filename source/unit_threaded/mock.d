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
            lines ~= `    called = true;`;
            lines ~= `    ` ~ m ~ `_called = tuple` ~ argNamesParens(arity!member) ~ `;`;
            lines ~= returnDefault;
            lines ~= `}`;
            lines ~= "";
            lines ~= `Tuple!` ~ parameters ~ ` ` ~ m ~ `_called;`;
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
    private string expected;
    auto _mocked = new MockAbstract;

    alias _mocked this;

    class MockAbstract: T {
        bool called;
        alias checkerFunc = string delegate() pure @safe;
        checkerFunc[] checkers;

        //pragma(msg, implMixinStr!T);
        mixin(implMixinStr!T);

        void expectedValues(string func, V...)(V values) {
            import std.conv: to;
            mixin(`checkers ~= () { return tuple(values) == ` ~ func ~ `_called ? "" : ` ~ func ~ `_called.to!string;};`);
        }
    }

    ~this() pure @safe {
        if(!verified) verify;
    }

    void expect(string func, V...)(V values) {
        expected = func;
        static if(V.length > 0) {
            _mocked.expectedValues!func(values);
        }
    }

    void verify(string file = __FILE__, ulong line = __LINE__) @safe pure {
        import unit_threaded.should: fail;
        verified = true;
        if(!called) fail("Expected call to " ~ expected ~ " did not happen", file, line);
        foreach(checker; _mocked.checkers) {
            auto res = checker();
            if(res != "")
                fail(expected ~ " was called with wrong parameters " ~ res, file, line);
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
        m.verify.shouldThrowWithMessage(`foo was called with wrong parameters Tuple!(int, string)(5, "foobar")`);
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(5, "quux");
        fun(m);
        m.verify.shouldThrowWithMessage(`foo was called with wrong parameters Tuple!(int, string)(5, "foobar")`);
    }
}


@("mock interface negative test")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
    }

    auto m = mock!Foo;
    m.expect!"foo";
    m.verify.shouldThrowWithMessage("Expected call to foo did not happen");
}

// can't be in the unit test itself
version(unittest)
private class Class {
    abstract int foo(int, string) @safe pure;
    final int timesTwo(int i) @safe pure nothrow const { return i * 2; }
    int timesThree(int i) @safe pure nothrow const { return i * 3; }
}

@("mock interface positive test")
@safe pure unittest {

    int fun(Class f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Class;
    m.expect!"foo";
    fun(m);
}
