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
    TestFunction testFunction; ///only used for functions, null for classes
    bool hidden;
    bool shouldFail;
    bool singleThreaded;
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
    TestData[] testData;

    foreach(module_; MOD_SYMBOLS) {
        testData ~= moduleUnitTests!module_;
    }

    return testData;
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
        testData ~= TestData(unittestName!(test, index),
                             &test,
                             HasAttribute!(test, HiddenTest),
                             HasAttribute!(test, ShouldFail),
                             HasAttribute!(test, SingleThreaded),
                             );
    }
    return testData;
}


unittest {

    import unit_threaded.asserts;
    import std.algorithm;
    import std.array;


    //helper function for the unittest blocks below
    auto addModPrefix(string[] elements, string module_ = "unit_threaded.tests.module_with_tests") nothrow {
        return elements.map!(a => module_ ~ "." ~ a).array;
    }

    const expected = addModPrefix(["unittest0", "unittest1", "myUnitTest"]);

    {
        import unit_threaded.tests.module_with_tests; //defines tests and non-tests
        const actual = moduleUnitTests!(unit_threaded.tests.module_with_tests).map!(a => a.name).array;
        assertEqual(actual, expected);
    }

    {
        const actual = allTestCaseData!("unit_threaded.tests.module_with_tests").map!(a => a.name).array;
        assertEqual(actual, expected);
    }
}
