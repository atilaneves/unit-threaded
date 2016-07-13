module unit_threaded.mock;

import std.traits;

version(unittest) {
    import unit_threaded.asserts;
    import unit_threaded.should;
}


alias Identity(alias T) = T;

string implMixinStr(T)() {
    string ret;
    foreach(m; __traits(allMembers, T)) {
        alias member = Identity!(__traits(getMember, T, m));
        static if(__traits(isAbstractFunction, member)) {
            ret ~= ReturnType!member.stringof ~ " " ~ m ~
                 Parameters!member.stringof ~ " {\n" ~
                "    called = true;\n" ~
                `    return ` ~ ReturnType!member.stringof ~ ".init;\n" ~
                "}";
        }
    }

    return ret;
}

mixin template Foo(T) {
}

struct Mock(T) {

    MockInterface _mocked = new MockInterface;

    alias _mocked this;

    class MockInterface: T {
        bool called;
        //pragma(msg, implMixinStr!T);
        mixin(implMixinStr!T);
    }

    void expect(U...)(U) {
    }

    void verify(string file = __FILE__, ulong line = __LINE__) {
        if(!called) throw new Exception("Expected call did not happen", file, line);
    }
}

auto mock(T)() {
    return Mock!T();
}

@("mock interface positive test")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
    }

    int fun(Foo f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Foo;
    m.expect(&m.foo);
    fun(m);
    m.verify;
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
