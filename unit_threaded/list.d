module unit_threaded.list;

import std.traits;
import std.uni;
import std.typecons;
import std.typetuple;
import unit_threaded.check; //UnitTest
/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */

private template HasUnitTestAttr(alias mod, alias T) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    static if(__traits(getProtection, mixin(T)) != "private") {
        enum index = staticIndexOf!(UnitTest, __traits(getAttributes, mixin(T)));
        static if(index >= 0) {
            enum HasUnitTestAttr = true;
        } else {
            enum HasUnitTestAttr = false;
        }
    } else {
        enum HasUnitTestAttr = false;
    }
}


string[] getTestClassNames(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes;
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && !isSomeFunction!(mixin(klass)) &&
                  (__traits(hasMember, mixin(klass), "test") ||
                   HasUnitTestAttr!(mod, klass))) {
            classes ~= fullyQualifiedName!mod ~ "." ~ klass;
        }
    }

    return classes;
}

alias void function() TestFunction;
alias Tuple!(string, TestFunction) TestFunctionTuple;
struct TestFunctionData {
    string name;
    TestFunction func;
}


private template IsTestFunction(alias mod, alias T) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible

    enum prefix = "test";
    enum minSize = prefix.length + 1;

    static if(isSomeFunction!(mixin(T)) &&
              T.length >= minSize && T[0 .. prefix.length] == "test" &&
              isUpper(T[prefix.length])) {
        enum IsTestFunction = true;
    } else {
        enum IsTestFunction = false;
    }
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestFunctionData structs
 */
auto getTestFunctions(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestFunctionData[] functions;
    foreach(moduleMember; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(moduleMember)) &&
                  (IsTestFunction!(mod, moduleMember) ||
                   (isSomeFunction!(mixin(moduleMember)) && HasUnitTestAttr!(mod, moduleMember)))) {
            //I couldn't find a way to check for access here. I tried __traits(getProtection)
            //and got 'public' for private functions
            static immutable funcName = fullyQualifiedName!mod ~ "." ~ moduleMember;
            static immutable funcAddr = "&" ~ funcName;

            mixin("functions ~= TestFunctionData(\"" ~ funcName ~ "\", " ~ funcAddr ~ ");");
        }
    }

    return functions;
}


private auto addModule(string[] elements, string mod = "unit_threaded.tests.module_with_tests") nothrow {
    import std.algorithm;
    import std.array;
    return array(map!(a => mod ~ "." ~ a)(elements));
}

import unit_threaded.tests.module_with_tests; //defines tests and non-tests
import unit_threaded.asserts;


unittest {
    const expected = addModule([ "FooTest", "BarTest", "Blergh"]);
    const actual = getTestClassNames!(unit_threaded.tests.module_with_tests)();
    assertEqual(actual, expected);
}

unittest {
    static assert(IsTestFunction!(unit_threaded.tests.module_with_tests, "testFoo"));
    static assert(!IsTestFunction!(unit_threaded.tests.module_with_tests, "funcThatShouldShowUpCosOfAttr"));
}

unittest {
    import std.algorithm;
    import std.array;
    auto expected = addModule([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr" ]);
    auto actual = map!(a => a.name)(getTestFunctions!(unit_threaded.tests.module_with_tests)());
    assertEqual(array(actual), expected);
}
