module unit_threaded.list;

import std.traits;
import std.uni;
import std.typetuple;
import unit_threaded.check; //enum labels

private template HasAttribute(alias mod, string T, alias A) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    enum index = staticIndexOf!(A, __traits(getAttributes, mixin(T)));
    static if(index >= 0) {
        enum HasAttribute = true;
    } else {
        enum HasAttribute = false;
    }

}

/**
 * Common data for test functions and test classes
 */
alias void function() TestFunction;
struct TestData {
    string name;
    bool hidden;
    TestFunction test; //only used for functions, null for classes
    bool singleThreaded;
}

/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
auto getTestClassNames(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] classes;
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && !isSomeFunction!(mixin(klass)) &&
                  !HasAttribute!(mod, klass, DontTest) &&
                  (__traits(hasMember, mixin(klass), "test") ||
                   HasAttribute!(mod, klass, UnitTest))) {
            classes ~= TestData(fullyQualifiedName!mod ~ "." ~ klass,
                                HasAttribute!(mod, klass, HiddenTest),
                                null, //TestFunction
                                HasAttribute!(mod, klass, SingleThreaded));
        }
    }

    return classes;
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
auto getTestFunctions(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] functions;
    foreach(moduleMember; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(moduleMember)) && !HasAttribute!(mod, moduleMember, DontTest) &&
                  (IsTestFunction!(mod, moduleMember) ||
                   (isSomeFunction!(mixin(moduleMember)) && HasAttribute!(mod, moduleMember, UnitTest)))) {
            enum funcName = fullyQualifiedName!mod ~ "." ~ moduleMember;
            enum funcAddr = "&" ~ funcName;

            mixin(`functions ~= TestData("` ~ funcName ~ `", ` ~
                  HasAttribute!(mod, moduleMember, HiddenTest).stringof ~ ", " ~ funcAddr ~
                  ", " ~  HasAttribute!(mod, moduleMember, SingleThreaded).stringof ~ ");");

        }
    }

    return functions;
}

private template IsTestFunction(alias mod, alias T) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible

    enum prefix = "test";
    enum minSize = prefix.length + 1;

    static if(isSomeFunction!(mixin(T)) &&
              T.length >= minSize && T[0 .. prefix.length] == prefix &&
              isUpper(T[prefix.length])) {
        enum IsTestFunction = true;
    } else {
        enum IsTestFunction = false;
    }
}


//helper function for the unittest blocks below
private auto addModule(string[] elements, string mod = "unit_threaded.tests.module_with_tests") nothrow {
    import std.algorithm;
    import std.array;
    return array(map!(a => mod ~ "." ~ a)(elements));
}

import unit_threaded.tests.module_with_tests; //defines tests and non-tests
import unit_threaded.asserts;


unittest {
    import std.algorithm;
    import std.array;
    const expected = addModule([ "FooTest", "BarTest", "Blergh"]);
    const actual = getTestClassNames!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
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
    auto actual = getTestFunctions!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}
