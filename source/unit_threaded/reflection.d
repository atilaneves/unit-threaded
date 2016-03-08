module unit_threaded.reflection;

import unit_threaded.attrs;
import unit_threaded.uda;
import std.traits;
import std.typetuple;

/**
 * Common data for test functions and test classes
 */
alias void delegate() TestFunction;
struct TestData {
    string name;
    TestFunction testFunction; ///only used for functions, null for classes
    bool hidden;
    bool shouldFail;
    bool singleThreaded;
    bool builtin;
    string suffix; // append to end of getPath

    string getPath() const pure nothrow {
        string path = name.dup;
        if(suffix) path ~= "." ~ suffix;
        return path;
    }
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module strings
 */
const(TestData)[] allTestData(MOD_STRINGS...)() if(allSatisfy!(isSomeString, typeof(MOD_STRINGS))) {

    string getModulesString() {
        import std.array: join;
        string[] modules;
        foreach(module_; MOD_STRINGS) modules ~= module_;
        return modules.join(", ");
    }

    enum modulesString =  getModulesString;
    mixin("import " ~ modulesString ~ ";");
    mixin("return allTestData!(" ~ modulesString ~ ");");
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module symbols
 */
const(TestData)[] allTestData(MOD_SYMBOLS...)() if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    auto allTestsWithFunc(string expr, MOD_SYMBOLS...)() pure {
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
TestData[] moduleUnitTests(alias module_)() pure nothrow {

    // Return a name for a unittest block. If no @Name UDA is found a name is
    // created automatically, else the UDA is used.
    string unittestName(alias test, int index)() @safe nothrow {
        import std.conv;
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        enum nameAttrs = getUDAs!(test, Name);
        static assert(nameAttrs.length == 0 || nameAttrs.length == 1, "Found multiple Name UDAs on unittest");

        enum strAttrs = Filter!(isStringUDA, __traits(getAttributes, test));
        enum hasName = nameAttrs.length || strAttrs.length == 1;
        enum prefix = fullyQualifiedName!module_ ~ ".";

        static if(hasName) {
            static if(nameAttrs.length == 1)
                return prefix ~ nameAttrs[0].value;
            else
                return prefix ~ strAttrs[0];
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
        enum hidden = hasUDA!(test, HiddenTest);
        enum shouldFail = hasUDA!(test, ShouldFail);
        enum singleThreaded = hasUDA!(test, Serial);
        enum builtin = true;
        testData ~= TestData(name, (){ test(); }, hidden, shouldFail, singleThreaded, builtin);
    }
    return testData;
}

private template isStringUDA(alias T) {
    static if(__traits(compiles, isSomeString!(typeof(T))))
        enum isStringUDA = isSomeString!(typeof(T));
    else
        enum isStringUDA = false;
}

unittest {
    static assert(isStringUDA!"foo");
    static assert(!isStringUDA!5);
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
TestData[] moduleTestClasses(alias module_)() pure nothrow {

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

    return moduleTestData!(module_, isTestClass);
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
TestData[] moduleTestFunctions(alias module_)() pure {

    template isTestFunction(alias module_, string moduleMember) {
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
        // AliasSeq aren't passed as a single argument, but isSomeFunction only takes one
        static if(AliasSeq!(mixin(moduleMember)).length == 1 && isSomeFunction!(mixin(moduleMember))) {
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

    return moduleTestData!(module_, isTestFunction);
}

private struct TestFunctionSuffix {
    TestFunction testFunction;
    string suffix; // used for values automatically passed to functions
}


private TestData[] moduleTestData(alias module_, alias pred)() pure {
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, module_)) {

        enum notPrivate = __traits(compiles, mixin(moduleMember)); //only way I know to check if private

        static if(notPrivate && pred!(module_, moduleMember) &&
                  !HasAttribute!(module_, moduleMember, DontTest)) {

            /*
             This function returns an array because it might find a test function that takes
             a parameter with UDAs of the appropriate type. One "real" test function is returned
             for each one of those. Examples:
             ------
             void testFoo() {} // -> the array contains one element, testFoo
             @(1, 2, 3) void testBar(int) {} // The array contains 3 elements, one for each UDA value
             ------
             */

            TestFunctionSuffix[] getTestFunctions(alias module_, string moduleMember)() {
                //returns delegates for test functions, null for test classes
                static if(__traits(compiles, &__traits(getMember, module_, moduleMember))) {

                    enum func = &__traits(getMember, module_, moduleMember);
                    enum arity = arity!func;

                    static assert(arity == 0 || arity == 1, "Test functions may take at most one parameter");

                    static if(arity == 0)
                        return [ TestFunctionSuffix((){ func(); }) ]; //simple case, just call it
                    else {

                        // check to see if the function has UDAs for parameters to be passed to it

                        alias params = Parameters!func;
                        static assert(params.length == 1, "Test functions may take at most one parameter");

                        alias values = GetAttributes!(module_, moduleMember, params[0]);
                        import std.conv;
                        static assert(values.length > 0,
                                      text("Test functions with a parameter of type <", params[0].stringof,
                                       "> must have value UDAs of the same type"));

                        TestFunctionSuffix[] functions;
                        foreach(v; values) functions ~= TestFunctionSuffix((){ func(v); }, v.to!string);
                        return functions;
                    }
                } else {
                    //test class
                    return [TestFunctionSuffix(null)];
                }
            }

            auto functions = getTestFunctions!(module_, moduleMember);
            foreach(f; functions) {
                //if there is more than one function, they're all single threaded - multiple values per test call
                //this is slightly hackish but works and actually makes sense - it causes factory to make
                //a CompositeTestCase out of them
                immutable singleThreaded = functions.length > 1 || HasAttribute!(module_, moduleMember, Serial);
                enum builtin = false;
                testData ~= TestData(fullyQualifiedName!module_~ "." ~ moduleMember,
                                     f.testFunction,
                                     HasAttribute!(module_, moduleMember, HiddenTest),
                                     HasAttribute!(module_, moduleMember, ShouldFail),
                                     singleThreaded,
                                     builtin,
                                     f.suffix);
            }
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
