module unit_threaded.mock;

import std.traits;

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

            enum returnType = ReturnType!member.stringof;

            static if(is(ReturnType!member == void))
                enum returnDefault = "";
            else
                enum returnDefault = `    return ` ~ returnType ~ ".init;";

            lines ~= `override ` ~ returnType ~ " " ~ m ~ Parameters!member.stringof ~ " {";
            lines ~= `   called = true;`;
            lines ~= returnDefault;
            lines ~= `}`;
        }
    }

    return lines.join("\n");
}


struct Mock(T) {

    private bool verified;
    auto _mocked = new MockAbstract;

    alias _mocked this;

    class MockAbstract: T {
        bool called;
        //pragma(msg, implMixinStr!T);
        mixin(implMixinStr!T);
    }

    ~this() {
        if(!verified) verify;
    }

    void expect(U...)(U) {
    }

    void verify(string file = __FILE__, ulong line = __LINE__) {
        import unit_threaded.should: fail;
        verified = true;
        if(!called) fail("Expected call did not happen", file, line);
    }
}

auto mock(T)() {
    return Mock!T();
}

@("mock interface positive test")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
        void bar() @safe pure;
    }

    int fun(Foo f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Foo;
    m.expect(&m.foo);
    fun(m);
}

@("mock interface negative test")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
    }

    auto m = mock!Foo;
    m.expect(&m.foo);
    m.verify.shouldThrowWithMessage("Expected call did not happen");
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
    m.expect(&m.foo);
    fun(m);
}
