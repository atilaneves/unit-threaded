module unit_threaded.reflection;

import unit_threaded.attrs;
import unit_threaded.uda;
import std.traits;
import std.typetuple;

/**
 * Common data for test functions and test classes
 */
alias void function() TestFunction;
struct TestData {
    string name;
    bool hidden;
    bool shouldFail;
    TestFunction testFunction; ///only used for functions, null for classes
    bool singleThreaded;
    bool builtin;
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module strings
 */
const(TestData)[] allTestCaseData(MOD_STRINGS...)() if(allSatisfy!(isSomeString, typeof(MOD_STRINGS))) {

    string getModulesString() {
        import std.array: join;
        string[] modules;
        foreach(module_; MOD_STRINGS) modules ~= module_;
        return modules.join(", ");
    }

    enum modulesString =  getModulesString;
    mixin("import " ~ modulesString ~ ";");
    mixin("return allTestCaseData!(" ~ modulesString ~ ");");
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module symbols
 */
const(TestData)[] allTestCaseData(MOD_SYMBOLS...)() if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    auto allTestsWithFunc(string expr, MOD_SYMBOLS...)() pure nothrow {
        //tests is whatever type expr returns
        ReturnType!(mixin(expr ~ q{!(MOD_SYMBOLS[0])})) tests;
        foreach(module_; TypeTuple!MOD_SYMBOLS) {
            tests ~= mixin(expr ~ q{!module_()}); //e.g. tests ~= moduleTestClasses!module_
        }
        return tests;
    }

    return allTestsWithFunc!(q{moduleTestClasses}, MOD_SYMBOLS) ~
           allTestsWithFunc!(q{moduleTestFunctions}, MOD_SYMBOLS) ~
           allTestsWithFunc!(q{moduleUnitTests}, MOD_SYMBOLS);
}


/**
 * Finds all built-in unittest blocks in the given module.
 * @return An array of TestData structs
 */
auto moduleUnitTests(alias module_)() pure nothrow {

    // Return a name for a unittest block. If no @Name UDA is found a name is
    // created automatically, else the UDA is used.
    string unittestName(alias test, int index)() @safe nothrow {
        import std.conv;
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        enum isName(alias T) = is(typeof(T)) && is(typeof(T) == Name);
        alias names = Filter!(isName, __traits(getAttributes, test));
        static assert(names.length == 0 || names.length == 1, "Found multiple Name UDAs on unittest");
        enum prefix = fullyQualifiedName!module_ ~ ".";

        static if(names.length == 1) {
            return prefix ~ names[0].value;
        } else {
            string name;
            try {
                return prefix ~ "unittest" ~ (index).to!string;
            } catch(Exception) {
                assert(false, text("Error converting ", index, " to string"));
            }
        }
    }

    TestData[] testData;
    foreach(index, test; __traits(getUnitTests, module_)) {
        enum name = unittestName!(test, index);
        enum hidden = false;
        enum shouldFail = false;
        enum singleThreaded = false;
        enum builtin = true;
        testData ~= TestData(name, hidden, shouldFail, &test, singleThreaded, builtin);
    }
    return testData;
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
auto moduleTestClasses(alias module_)() pure nothrow {

    template isTestClass(alias module_, string moduleMember) {
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
        static if(!__traits(compiles, isAggregateType!(mixin(moduleMember)))) {
            enum isTestClass = false;
        } else static if(!isAggregateType!(mixin(moduleMember))) {
            enum isTestClass = false;
        } else static if(!__traits(compiles, mixin("new " ~ moduleMember))) {
            enum isTestClass = false; //can't new it, can't use it
        } else {
            enum hasUnitTest = HasAttribute!(module_, moduleMember, UnitTest);
            enum hasTestMethod = __traits(hasMember, mixin(moduleMember), "test");
            enum isTestClass = hasTestMethod || hasUnitTest;
        }
    }

    return moduleTestCases!(module_, isTestClass);
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
auto moduleTestFunctions(alias module_)() pure nothrow {

    template isTestFunction(alias module_, string moduleMember) {
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
        static if(isSomeFunction!(mixin(moduleMember))) {
            enum isTestFunction = hasTestPrefix!(module_, moduleMember) ||
                HasAttribute!(module_, moduleMember, UnitTest);
        } else {
            enum isTestFunction = false;
        }
    }

    template hasTestPrefix(alias module_, string member) {
        import std.uni: isUpper;
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        enum prefix = "test";
        enum minSize = prefix.length + 1;

        static if(isSomeFunction!(mixin(member)) &&
                  member.length >= minSize && member[0 .. prefix.length] == prefix &&
                  isUpper(member[prefix.length])) {
            enum hasTestPrefix = true;
        } else {
            enum hasTestPrefix = false;
        }
    }

    return moduleTestCases!(module_, isTestFunction);
}


private auto moduleTestCases(alias module_, alias pred)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, module_)) {

        enum notPrivate = __traits(compiles, mixin(moduleMember)); //only way I know to check if private

        static if(notPrivate && pred!(module_, moduleMember) &&
                  !HasAttribute!(module_, moduleMember, DontTest)) {

            TestFunction getTestFunction(alias module_, string moduleMember)() pure nothrow {
                //returns a function pointer for test functions, null for test classes
                static if(__traits(compiles, &__traits(getMember, module_, moduleMember))) {
                    return &__traits(getMember, module_, moduleMember);
                } else {
                    return null;
                }
            }

            testData ~= TestData(fullyQualifiedName!module_~ "." ~ moduleMember,
                                 HasAttribute!(module_, moduleMember, HiddenTest),
                                 HasAttribute!(module_, moduleMember, ShouldFail),
                                 getTestFunction!(module_, moduleMember),
                                 HasAttribute!(module_, moduleMember, SingleThreaded));
        }
    }

    return testData;
}



import unit_threaded.tests.module_with_tests; //defines tests and non-tests
import unit_threaded.asserts;
import std.algorithm;
import std.array;

//helper function for the unittest blocks below
private auto addModPrefix(string[] elements, string module_ = "unit_threaded.tests.module_with_tests") nothrow {
    return elements.map!(a => module_ ~ "." ~ a).array;
}

unittest {
    const expected = addModPrefix([ "FooTest", "BarTest", "Blergh"]);
    const actual = moduleTestClasses!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}

unittest {
    const expected = addModPrefix([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr" ]);
    const actual = moduleTestFunctions!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}


unittest {
    const expected = addModPrefix(["unittest0", "unittest1", "myUnitTest"]);
    const actual = moduleUnitTests!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
    assertEqual(actual, expected);
}
