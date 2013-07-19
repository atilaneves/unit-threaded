module unit_threaded.list;

import std.traits;
import std.uni;
import std.typecons;

/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
string[] getTestClassNames(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes;
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
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

/**
 * Finds all test functions in the given module.
 * Returns an array of TestFunctionData structs
 */
auto getTestFunctions(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestFunctionData[] functions;
    foreach(moduleMember; __traits(allMembers, mod)) {
        static immutable prefix = "test";
        static immutable minSize = prefix.length + 1;
        static if(moduleMember.length >= minSize && moduleMember[0 .. prefix.length] == "test" &&
                  isUpper(moduleMember[prefix.length])) {
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
    const expected = addModule([ "FooTest", "BarTest" ]);
    const actual = getTestClassNames!(unit_threaded.tests.module_with_tests)();
    assertEqual(actual, expected);
}
