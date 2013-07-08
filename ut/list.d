module ut.list;

import std.traits;

string[] getTestClassNames(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes = [];
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            classes ~= fullyQualifiedName!mod ~ "." ~ klass;
        }
    }

    return classes;
}

string[] getTestFunctions(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] functions = [];
    foreach(moduleMember; __traits(allMembers, mod)) {
        static immutable prefix = "test";
        static if(moduleMember.length >= prefix.length && moduleMember[0 .. prefix.length] == "test") {
            functions ~= fullyQualifiedName!mod ~ "." ~ moduleMember;
        }
    }

    return functions;
}

string[] getTestables(alias mod)() {
    return getTestClassNames!mod ~ getTestFunctions!mod;
}

private void testFoo() {}
private void testBar() {}
private void someFun() {}
private class FooTest { void test() { } }
private class Bar { }

unittest {
    import std.conv;
    const actualFuncs = getTestFunctions!(mixin(__MODULE__))();
    const expectedFuncs = [ "ut.list.testFoo", "ut.list.testBar" ];
    assert(actualFuncs == expectedFuncs, "Expected " ~ to!string(expectedFuncs) ~
           ", got: " ~ to!string(actualFuncs));
}
