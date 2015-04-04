module unit_threaded.reflection;

import std.traits;
import std.uni;
import std.typetuple;
import unit_threaded.check; //enum labels

/**
 * Common data for test functions and test classes
 */
alias void function() TestFunction;
struct TestData {
    string name;
    bool hidden;
    bool shouldFail;
    TestFunction test; //only used for functions, null for classes
    bool singleThreaded;
    bool builtin;
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module strings
 */
const(TestData)[] getAllTestCaseData(MOD_STRINGS...)() if(allSatisfy!(isSomeString, typeof(MOD_STRINGS))) {
    enum modulesString = getModulesCompileString!MOD_STRINGS; //e.g. foo, bar, baz
    mixin("import " ~ modulesString ~ ";");
    mixin("return getAllTestCaseData!(" ~ modulesString ~ ");");
}


private string getModulesCompileString(MOD_STRINGS...)() {
    import std.array;
    string[] modules;
    foreach(mod; MOD_STRINGS) modules ~= mod;
    return modules.join(", ");
}

/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module symbols
 */
const(TestData)[] getAllTestCaseData(MOD_SYMBOLS...)() if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    auto getAllTestsWithFunc(string expr, MOD_SYMBOLS...)() pure nothrow {
        //tests is whatever type expr returns
        ReturnType!(mixin(expr ~ q{!(MOD_SYMBOLS[0])})) tests;
        foreach(mod; TypeTuple!MOD_SYMBOLS) {
            tests ~= mixin(expr ~ q{!mod()}); //e.g. tests ~= getTestClasses!mod
        }
        return tests;
    }

    return getAllTestsWithFunc!(q{getTestClasses}, MOD_SYMBOLS) ~
           getAllTestsWithFunc!(q{getTestFunctions}, MOD_SYMBOLS) ~
           getAllTestsWithFunc!(q{getBuiltinTests}, MOD_SYMBOLS);
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
auto getTestClasses(alias mod)() pure nothrow {
    return getTestCases!(mod, isTestClass);
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
auto getTestFunctions(alias mod)() pure nothrow {
    return getTestCases!(mod, isTestFunction);
}

private enum isName(alias T) = is(typeof(T)) && is(typeof(T) == Name);

unittest {
    static assert(isName!(Name()));
    static assert(!isName!Name);
}

/**
 * Finds all built-in unittest blocks in the given module.
 * @return An array of TestData structs
 */
auto getBuiltinTests(alias mod)() pure nothrow {
    TestData[] testData;
    foreach(index, test; __traits(getUnitTests, mod)) {
        enum name = unittestName!(mod, test, index);
        enum hidden = false;
        enum shouldFail = false;
        enum singleThreaded = false;
        enum builtin = true;
        testData ~= TestData(name, hidden, shouldFail, &test, singleThreaded, builtin);
    }
    return testData;
}

private string unittestName(alias mod, alias test, int index)() @safe nothrow {
    import std.conv;
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible

    alias names = Filter!(isName, __traits(getAttributes, test));
    static assert(names.length == 0 || names.length == 1, "Found multiple Name UDAs on unittest");
    enum prefix = fullyQualifiedName!mod ~ ".";

    static if(names.length == 1) {
        return  prefix ~ names[0].value;
    } else {
        string name;
        try {
            return prefix ~ "unittest" ~ (index).to!string;
        } catch(Exception) {
            assert(false, text("Error converting ", index, " to string"));
        }
    }
}

private template HasAttribute(alias mod, string member, alias A) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    enum index = staticIndexOf!(A, __traits(getAttributes, mixin(member)));
    static if(index >= 0) {
        enum HasAttribute = true;
    } else {
        enum HasAttribute = false;
    }
}


private template HasHidden(alias mod, string member) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    alias attrs = Filter!(isAHiddenStruct, __traits(getAttributes, mixin(member)));
    static assert(attrs.length == 0 || attrs.length == 1,
                  "Maximum number of HiddenTest attributes is 1");
    static if(attrs.length == 0) {
        enum HasHidden = false;
    } else {
        enum HasHidden = true;
    }
}

private template HasShouldFail(alias mod, string member) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    alias attrs = Filter!(isAShouldFailStruct, __traits(getAttributes, mixin(member)));
    static assert(attrs.length == 0 || attrs.length == 1,
                  "Maximum number of ShouldFail attributes is 1");
    static if(attrs.length == 0) {
        enum HasShouldFail = false;
    } else {
        enum HasShouldFail = true;
    }
}


private auto getTestCases(alias mod, alias pred)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, mod)) {

        enum notPrivate = __traits(compiles, mixin(moduleMember)); //only way I know to check if private

        static if(notPrivate && pred!(mod, moduleMember)) {
            static if(!HasAttribute!(mod, moduleMember, DontTest)) {
                testData ~= createTestData!(mod, moduleMember);
            }
        }
    }

    return testData;
}

private auto createTestData(alias mod, string moduleMember)() pure nothrow {
    TestFunction getTestFunction(alias mod, string moduleMember)() {
    //returns a function pointer for test functions, null for test classes
        static if(__traits(compiles, &__traits(getMember, mod, moduleMember))) {
            return &__traits(getMember, mod, moduleMember);
        } else {
            return null;
        }
    }

    return TestData(fullyQualifiedName!mod ~ "." ~ moduleMember,
                    HasHidden!(mod, moduleMember),
                    HasShouldFail!(mod, moduleMember),
                    getTestFunction!(mod, moduleMember),
                    HasAttribute!(mod, moduleMember, SingleThreaded));
}

private template isTestClass(alias mod, string moduleMember) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    static if(__traits(compiles, isAggregateType!(mixin(moduleMember)))) {
        static if(isAggregateType!(mixin(moduleMember))) {

            enum hasUnitTest = HasAttribute!(mod, moduleMember, UnitTest);
            enum hasTestMethod = __traits(hasMember, mixin(moduleMember), "test");

            enum isTestClass = hasTestMethod || hasUnitTest;
        } else {
            enum isTestClass = false;
        }
    } else {
        enum isTestClass = false;
    }
}


private template isTestFunction(alias mod, string moduleMember) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    static if(isSomeFunction!(mixin(moduleMember))) {
        enum isTestFunction = hasTestPrefix!(mod, moduleMember) ||
            HasAttribute!(mod, moduleMember, UnitTest);
    } else {
        enum isTestFunction = false;
    }
}

private template hasTestPrefix(alias mod, alias T) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible

    enum prefix = "test";
    enum minSize = prefix.length + 1;

    static if(isSomeFunction!(mixin(T)) &&
              T.length >= minSize && T[0 .. prefix.length] == "test" &&
              isUpper(T[prefix.length])) {
        enum hasTestPrefix = true;
    } else {
        enum hasTestPrefix = false;
    }
}


import unit_threaded.tests.module_with_tests; //defines tests and non-tests
import unit_threaded.asserts;
import std.algorithm;
import std.array;

//helper function for the unittest blocks below
private auto addModPrefix(string[] elements, string mod = "unit_threaded.tests.module_with_tests") nothrow {
    return elements.map!(a => mod ~ "." ~ a).array;
}

unittest {
    const expected = addModPrefix([ "FooTest", "BarTest", "Blergh"]);
    const actual = getTestClasses!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}

unittest {
    static assert(hasTestPrefix!(unit_threaded.tests.module_with_tests, "testFoo"));
    static assert(!hasTestPrefix!(unit_threaded.tests.module_with_tests, "funcThatShouldShowUpCosOfAttr"));
}

unittest {
    const expected = addModPrefix([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr" ]);
    const actual = getTestFunctions!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}


unittest {
    const expected = addModPrefix(["unittest0", "unittest1"]);
    const actual = getBuiltinTests!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}
