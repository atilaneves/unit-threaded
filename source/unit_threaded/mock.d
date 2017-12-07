module unit_threaded.mock;

import unit_threaded.from;

alias Identity(alias T) = T;
private enum isPrivate(T, string member) = !__traits(compiles, __traits(getMember, T, member));


string implMixinStr(T)() {
    import std.array: join;
    import std.format : format;
    import std.range : iota;
    import std.traits: functionAttributes, FunctionAttribute, Parameters, ReturnType, arity;
    import std.conv: text;

    if(!__ctfe) return null;

    string[] lines;

    string getOverload(in string memberName, in int i) {
        return `Identity!(__traits(getOverloads, T, "%s")[%s])`
            .format(memberName, i);
    }

    foreach(memberName; __traits(allMembers, T)) {

        static if(!isPrivate!(T, memberName)) {

            alias member = Identity!(__traits(getMember, T, memberName));

            static if(__traits(isVirtualMethod, member)) {
                foreach(i, overload; __traits(getOverloads, T, memberName)) {

                    static if(!(functionAttributes!member & FunctionAttribute.const_) &&
                              !(functionAttributes!member & FunctionAttribute.const_)) {

                        enum overloadName = text(memberName, "_", i);

                        enum overloadString = getOverload(memberName, i);
                        lines ~= "private alias %s_parameters = Parameters!(%s);".format(overloadName, overloadString);
                        lines ~= "private alias %s_returnType = ReturnType!(%s);".format(overloadName, overloadString);

                        static if(functionAttributes!member & FunctionAttribute.nothrow_)
                            enum tryIndent = "    ";
                        else
                            enum tryIndent = "";

                        static if(is(ReturnType!member == void))
                            enum returnDefault = "";
                        else {
                            enum varName = overloadName ~ `_returnValues`;
                            lines ~= `%s_returnType[] %s;`.format(overloadName, varName);
                            lines ~= "";
                            enum returnDefault = [`    if(` ~ varName ~ `.length > 0) {`,
                                                  `        auto ret = ` ~ varName ~ `[0];`,
                                                  `        ` ~ varName ~ ` = ` ~ varName ~ `[1..$];`,
                                                  `        return ret;`,
                                                  `    } else`,
                                                  `        return %s_returnType.init;`.format(overloadName)];
                        }

                        lines ~= `override ` ~ overloadName ~ "_returnType " ~ memberName ~
                            typeAndArgsParens!(Parameters!overload)(overloadName) ~ " " ~
                            functionAttributesString!member ~ ` {`;

                        static if(functionAttributes!member & FunctionAttribute.nothrow_)
                            lines ~= "try {";

                        lines ~= tryIndent ~ `    calledFuncs ~= "` ~ memberName ~ `";`;
                        lines ~= tryIndent ~ `    calledValues ~= tuple` ~ argNamesParens(arity!member) ~ `.to!string;`;

                        static if(functionAttributes!member & FunctionAttribute.nothrow_)
                            lines ~= "    } catch(Exception) {}";

                        lines ~= returnDefault;

                        lines ~= `}`;
                        lines ~= "";
                    }
                }
            }
        }
    }

    return lines.join("\n");
}

private string argNamesParens(int N) @safe pure {
    if(!__ctfe) return null;
    return "(" ~ argNames(N) ~ ")";
}

private string argNames(int N) @safe pure {
    import std.range;
    import std.algorithm;
    import std.conv;

    if(!__ctfe) return null;
    return iota(N).map!(a => "arg" ~ a.to!string).join(", ");
}

private string typeAndArgsParens(T...)(string prefix) {
    import std.array;
    import std.conv;
    import std.format : format;

    if(!__ctfe) return null;

    string[] parts;

    foreach(i, t; T)
        parts ~= "%s_parameters[%s] arg%s".format(prefix, i, i);
    return "(" ~ parts.join(", ") ~ ")";
}

private string functionAttributesString(alias F)() {
    import std.traits: functionAttributes, FunctionAttribute;
    import std.array: join;

    if(!__ctfe) return null;

    string[] parts;

    const attrs = functionAttributes!F;

    if(attrs & FunctionAttribute.pure_) parts ~= "pure";
    if(attrs & FunctionAttribute.nothrow_) parts ~= "nothrow";
    if(attrs & FunctionAttribute.trusted) parts ~= "@trusted";
    if(attrs & FunctionAttribute.safe) parts ~= "@safe";
    if(attrs & FunctionAttribute.nogc) parts ~= "@nogc";
    if(attrs & FunctionAttribute.system) parts ~= "@system";
    // const and immutable can't be done since the mock needs
    // to alter state
    // if(attrs & FunctionAttribute.const_) parts ~= "const";
    // if(attrs & FunctionAttribute.immutable_) parts ~= "immutable";
    if(attrs & FunctionAttribute.shared_) parts ~= "shared";

    return parts.join(" ");
}

mixin template MockImplCommon() {
    bool _verified;
    string[] expectedFuncs;
    string[] calledFuncs;
    string[] expectedValues;
    string[] calledValues;

    void expect(string funcName, V...)(auto ref V values) {
        import std.conv: to;
        import std.typecons: tuple;

        expectedFuncs ~= funcName;
        static if(V.length > 0)
            expectedValues ~= tuple(values).to!string;
        else
            expectedValues ~= "";
    }

    void expectCalled(string func, string file = __FILE__, size_t line = __LINE__, V...)(auto ref V values) {
        expect!func(values);
        verify(file, line);
        _verified = false;
    }

    void verify(string file = __FILE__, size_t line = __LINE__) @safe pure {
        import std.range: repeat, take, join;
        import std.conv: to;
        import unit_threaded.should: fail, UnitTestException;

        if(_verified)
            fail("Mock already _verified", file, line);

        _verified = true;

        for(int i = 0; i < expectedFuncs.length; ++i) {

            if(i >= calledFuncs.length)
                fail("Expected nth " ~ i.to!string ~ " call to " ~ expectedFuncs[i] ~ " did not happen", file, line);

            if(expectedFuncs[i] != calledFuncs[i])
                fail("Expected nth " ~ i.to!string ~ " call to " ~ expectedFuncs[i] ~ " but got " ~ calledFuncs[i] ~
                     " instead",
                     file, line);

            if(expectedValues[i] != calledValues[i] && expectedValues[i] != "")
                throw new UnitTestException([expectedFuncs[i] ~ " was called with unexpected " ~ calledValues[i],
                                             " ".repeat.take(expectedFuncs[i].length + 4).join ~
                                             "instead of the expected " ~ expectedValues[i]] ,
                                            file, line);
        }
    }
}

private enum isString(alias T) = is(typeof(T) == string);

struct Mock(T) {

    MockAbstract _impl;
    alias _impl this;

    class MockAbstract: T {
        import std.conv: to;
        import std.traits: Parameters, ReturnType;
        import std.typecons: tuple;

        //pragma(msg, "\nimplMixinStr for ", T, "\n\n", implMixinStr!T, "\n\n");
        mixin(implMixinStr!T);
        mixin MockImplCommon;
    }

    this(int/* force constructor*/) {
        _impl = new MockAbstract;
    }

    ~this() pure @safe {
        if(!_verified) verify;
    }

    void returnValue(string funcName, V...)(V values) {
        assertFunctionIsVirtual!funcName;
        return returnValue!(0, funcName)(values);
    }

    /**
       This version takes overloads into account. i is the overload
       index. e.g.:
       ---------
       interface Interface { void foo(int); void foo(string); }
       auto m = mock!Interface;
       m.returnValue!(0, "foo"); // int overload
       m.returnValue!(1, "foo"); // string overload
       ---------
     */
    void returnValue(int i, string funcName, V...)(V values) {
        assertFunctionIsVirtual!funcName;
        import std.conv: text;
        enum varName = funcName ~ text(`_`, i, `_returnValues`);
        foreach(v; values)
            mixin(varName ~ ` ~=  v;`);
    }

    private static void assertFunctionIsVirtual(string funcName)() {
        alias member = Identity!(__traits(getMember, T, funcName));

        static assert(__traits(isVirtualMethod, member),
                      "Cannot use returnValue on '" ~ funcName ~ "'");
    }
}

private string importsString(string module_, string[] Modules...) {
    if(!__ctfe) return null;

    auto ret = `import ` ~ module_ ~ ";\n";
    foreach(extraModule; Modules) {
        ret ~= `import ` ~ extraModule ~ ";\n";
    }
    return ret;
}

auto mock(T)() {
    return Mock!T(0);
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
                           `    source/unit_threaded/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, "foobar")` ~ "\n" ~
                           `    source/unit_threaded/mock.d:123 -        instead of the expected Tuple!(int, string)(6, "foobar")`);
    }

    {
        auto m = mock!Foo;
        m.expect!"foo"(5, "quux");
        fun(m);
        assertExceptionMsg(m.verify,
                           `    source/unit_threaded/mock.d:123 - foo was called with unexpected Tuple!(int, string)(5, "foobar")` ~ "\n" ~
                           `    source/unit_threaded/mock.d:123 -        instead of the expected Tuple!(int, string)(5, "quux")`);
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
version(unittest)
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

@("interface expectCalled")
@safe pure unittest {
    interface Foo {
        int foo(int, string) @safe pure;
        void bar() @safe pure;
    }

    int fun(Foo f) {
        return 2 * f.foo(5, "foobar");
    }

    auto m = mock!Foo;
    fun(m);
    m.expectCalled!"foo"(5, "foobar");
}

@("interface return value")
@safe pure unittest {
    import unit_threaded.should;

    interface Foo {
        int timesN(int i) @safe pure;
    }

    int fun(Foo f) {
        return f.timesN(3) * 2;
    }

    auto m = mock!Foo;
    m.returnValue!"timesN"(42);
    immutable res = fun(m);
    res.shouldEqual(84);
}

@("interface return values")
@safe pure unittest {
    import unit_threaded.should;

    interface Foo {
        int timesN(int i) @safe pure;
    }

    int fun(Foo f) {
        return f.timesN(3) * 2;
    }

    auto m = mock!Foo;
    m.returnValue!"timesN"(42, 12);
    fun(m).shouldEqual(84);
    fun(m).shouldEqual(24);
    fun(m).shouldEqual(0);
}

struct ReturnValues(string function_, T...) if(from!"std.meta".allSatisfy!(isValue, T)) {
    alias funcName = function_;
    alias Values = T;

    static auto values() {
        typeof(T[0])[] ret;
        foreach(val; T) {
            ret ~= val;
        }
        return ret;
    }
}

enum isReturnValue(alias T) = is(T: ReturnValues!U, U...);
enum isValue(alias T) = is(typeof(T));


/**
   Version of mockStruct that accepts 0 or more values of the same
   type. Whatever function is called on it, these values will
   be returned one by one. The limitation is that if more than one
   function is called on the mock, they all return the same type
 */
auto mockStruct(T...)(auto ref T returns) {

    struct Mock {

        MockImpl* _impl;
        alias _impl this;

        static struct MockImpl {

            static if(T.length > 0) {
                alias FirstType = typeof(returns[0]);
                private FirstType[] _returnValues;
            }

            mixin MockImplCommon;

            auto opDispatch(string funcName, V...)(auto ref V values) {

                import std.conv: to;
                import std.typecons: tuple;

                calledFuncs ~= funcName;
                calledValues ~= tuple(values).to!string;

                static if(T.length > 0) {

                    if(_returnValues.length == 0) return typeof(_returnValues[0]).init;
                    auto ret = _returnValues[0];
                    _returnValues = _returnValues[1..$];
                    return ret;
                }
            }
        }
    }

    Mock m;
    m._impl = new Mock.MockImpl;
    static if(T.length > 0) {
        foreach(r; returns)
            m._impl._returnValues ~= r;
    }

    return m;
}

// /**
//    Version of mockStruct that accepts a compile-time mapping
//    of function name to return values. Each template parameter
//    must be a value of type `ReturnValues`
//  */

auto mockStruct(T...)() if(T.length > 0 && from!"std.meta".allSatisfy!(isReturnValue, T)) {

    struct Mock {
        mixin MockImplCommon;

        int[string] _retIndices;

        auto opDispatch(string funcName, V...)(auto ref V values) {

            import std.conv: to;
            import std.typecons: tuple;

            calledFuncs ~= funcName;
            calledValues ~= tuple(values).to!string;

            foreach(retVal; T) {
                static if(retVal.funcName == funcName) {
                    return retVal.values[_retIndices[funcName]++];
                }
            }
        }

        auto lefoofoo() {
            return T[0].values[_retIndices["greet"]++];
        }

    }

    Mock mock;

    foreach(retVal; T) {
        mock._retIndices[retVal.funcName] = 0;
    }

    return mock;
}


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

@("mock struct negative")
@safe pure unittest {
    import unit_threaded.asserts;

    auto m = mockStruct;
    m.expect!"foobar";
    assertExceptionMsg(m.verify,
                       "    source/unit_threaded/mock.d:123 - Expected nth 0 call to foobar did not happen\n");

}


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
                       "    source/unit_threaded/mock.d:123 - foobar was called with unexpected Tuple!(int, string)(2, \"quux\")\n" ~
                       "    source/unit_threaded/mock.d:123 -           instead of the expected Tuple!(int, string)(3, \"quux\")");
}


@("struct return value")
@safe pure unittest {
    import unit_threaded.should;

    int fun(T)(T f) {
        return f.timesN(3) * 2;
    }

    auto m = mockStruct(42, 12);
    fun(m).shouldEqual(84);
    fun(m).shouldEqual(24);
    fun(m).shouldEqual(0);
    m.expectCalled!"timesN";
}

@("struct expectCalled")
@safe pure unittest {
    void fun(T)(T t) {
        t.foobar(2, "quux");
    }

    auto m = mockStruct;
    fun(m);
    m.expectCalled!"foobar"(2, "quux");
}

@("mockStruct different return types for different functions")
@safe pure unittest {
    import unit_threaded.should: shouldEqual;
    auto m = mockStruct!(ReturnValues!("length", 5),
                         ReturnValues!("greet", "hello"));
    m.length.shouldEqual(5);
    m.greet("bar").shouldEqual("hello");
    m.expectCalled!"length";
    m.expectCalled!"greet"("bar");
}

@("mockStruct different return types for different functions and multiple return values")
@safe pure unittest {
    import unit_threaded.should: shouldEqual;
    auto m = mockStruct!(ReturnValues!("length", 5, 3),
                         ReturnValues!("greet", "hello", "g'day"));
    m.length.shouldEqual(5);
    m.expectCalled!"length";
    m.length.shouldEqual(3);
    m.expectCalled!"length";

    m.greet("bar").shouldEqual("hello");
    m.expectCalled!"greet"("bar");
    m.greet("quux").shouldEqual("g'day");
    m.expectCalled!"greet"("quux");
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


auto throwStruct(E = from!"unit_threaded.should".UnitTestException, R = void)() {

    struct Mock {

        R opDispatch(string funcName, string file = __FILE__, size_t line = __LINE__, V...)
                    (auto ref V values) {
            throw new E(funcName ~ " was called", file, line);
        }
    }

    return Mock();
}

@("throwStruct default")
@safe pure unittest {
    import unit_threaded.should: shouldThrow, UnitTestException;
    auto m = throwStruct;
    m.foo.shouldThrow!UnitTestException;
    m.bar(1, "foo").shouldThrow!UnitTestException;
}

version(testing_unit_threaded) {
    class FooException: Exception {
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
}


@("throwStruct return value type")
@safe pure unittest {
    import unit_threaded.asserts;
    import unit_threaded.should: UnitTestException;
    auto m = throwStruct!(UnitTestException, int);
    int i;
    assertExceptionMsg(i = m.foo,
                       "    source/unit_threaded/mock.d:123 - foo was called");
    assertExceptionMsg(i = m.bar,
                       "    source/unit_threaded/mock.d:123 - bar was called");
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
