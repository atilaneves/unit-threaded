module unit_threaded.reflection;

import unit_threaded.attrs;
import unit_threaded.uda;
import unit_threaded.meta;
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
    string[] tags;

    string getPath() const pure nothrow {
        string path = name.dup;
        import std.array: empty;
        if(!suffix.empty) path ~= "." ~ suffix;
        return path;
    }

    bool isTestClass() @safe const pure nothrow {
        return testFunction is null;
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
        enum suffix = "";

        // let's check for @Values UDAs, which are actually of type ValuesImpl
        enum isValues(alias T) = is(typeof(T)) && is(typeof(T):ValuesImpl!U, U);
        enum valuesUDAs = Filter!(isValues, __traits(getAttributes, test));

        enum isTags(alias T) = is(typeof(T)) && is(typeof(T) == Tags);
        enum tags = tagsFromAttrs!(Filter!(isTags, __traits(getAttributes, test)));

        static if(valuesUDAs.length == 0) {
            testData ~= TestData(name, (){ test(); }, hidden, shouldFail, singleThreaded, builtin, suffix, tags);
        } else {
            static assert(valuesUDAs.length == 1, "Can only use @Values once");
            foreach(value; aliasSeqOf!(valuesUDAs[0].values)) {
                // force single threaded so a composite test case is created
                // we set a global static to the value the test expects then call the test function,
                // which can retrieve the value with getValue!T
                testData ~= TestData(name,
                                     () {
                                         ValueHolder!(typeof(value)).value = value;
                                         test();
                                     },
                                     hidden, shouldFail, true /*serial*/, builtin, suffix, tags);
            }
        }
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

private template isPrivate(alias module_, string moduleMember) {
    mixin(`import ` ~ fullyQualifiedName!module_ ~ `: ` ~ moduleMember ~ `;`);
    static if(__traits(compiles, isSomeFunction!(mixin(moduleMember)))) {
        enum isPrivate = false;
    } else {
        enum isPrivate = true;
    }
}


// if this member is a test function or class, given the predicate
private template PassesTestPred(alias module_, alias pred, string moduleMember) {
    //should be the line below instead but a compiler bug prevents it
    //mixin(importMember!module_(moduleMember));
    mixin("import " ~ fullyQualifiedName!module_ ~ ";");
    enum notPrivate = __traits(compiles, mixin(moduleMember)); //only way I know to check if private
    //enum notPrivate = !isPrivate!(module_, moduleMember);
    static if(notPrivate)
        enum PassesTestPred = notPrivate && pred!(module_, moduleMember) &&
                              !HasAttribute!(module_, moduleMember, DontTest);
    else
        enum PassesTestPred = false;
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
TestData[] moduleTestClasses(alias module_)() pure nothrow {

    template isTestClass(alias module_, string moduleMember) {
        mixin(importMember!module_(moduleMember));
        static if(isPrivate!(module_, moduleMember)) {
            enum isTestClass = false;
        } else static if(!__traits(compiles, isAggregateType!(mixin(moduleMember)))) {
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


    return moduleTestData!(module_, isTestClass, memberTestData);
}


/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
TestData[] moduleTestFunctions(alias module_)() pure {

    enum isTypesAttr(alias T) = is(T) && is(T:Types!U, U...);

    template isTestFunction(alias module_, string moduleMember) {
        mixin(importMember!module_(moduleMember));

        static if(isPrivate!(module_, moduleMember)) {
            enum isTestFunction = false;
        } else static if(AliasSeq!(mixin(moduleMember)).length != 1) {
            enum isTestFunction = false;
        } else static if(isSomeFunction!(mixin(moduleMember))) {
            enum isTestFunction = hasTestPrefix!(module_, moduleMember) ||
                                  HasAttribute!(module_, moduleMember, UnitTest);
        } else {
            // in this case we handle the possibility of a template function with
            // the @Types UDA attached to it
            alias types = GetTypes!(mixin(moduleMember));
            enum isTestFunction = hasTestPrefix!(module_, moduleMember) &&
                                  types.length > 0 &&
                                  is(typeof(() {
                                      mixin(moduleMember ~ `!` ~ types[0].stringof ~ `;`);
                                  }));
        }
    }

    template hasTestPrefix(alias module_, string member) {
        import std.uni: isUpper;
        mixin(importMember!module_(member));

        enum prefix = "test";
        enum minSize = prefix.length + 1;

        static if(member.length >= minSize && member[0 .. prefix.length] == prefix &&
                  isUpper(member[prefix.length])) {
            enum hasTestPrefix = true;
        } else {
            enum hasTestPrefix = false;
        }
    }


    return moduleTestData!(module_, isTestFunction, createFuncTestData);
}

private TestData[] createFuncTestData(alias module_, string moduleMember)() {
    mixin(importMember!module_(moduleMember));
    /*
      Get all the test functions for this module member. There might be more than one
      when using parametrized unit tests.

      Examples:
      ------
      void testFoo() {} // -> the array contains one element, testFoo
      @(1, 2, 3) void testBar(int) {} // The array contains 3 elements, one for each UDA value
      @Types!(int, float) void testBaz(T)() {} //The array contains 2 elements, one for each type
      ------
    */
    // if the predicate returned true (which is always the case here), then it's either
    // a regular function or a templated one. If regular is has a pointer to it
    enum isRegularFunction = __traits(compiles, &__traits(getMember, module_, moduleMember));

    static if(isRegularFunction) {

        enum func = &__traits(getMember, module_, moduleMember);
        enum arity = arity!func;

        static assert(arity == 0 || arity == 1, "Test functions may take at most one parameter");

        static if(arity == 0)
            // the reason we're creating a lambda to call the function is that test functions
            // are ordinary functions, but we're storing delegates
            return [ memberTestData!(module_, moduleMember)(() { func(); }) ]; //simple case, just call the function
        else {

            // the function takes a parameter, check if it has UDAs for value parameters to be passed to it
            alias params = Parameters!func;
            static assert(params.length == 1, "Test functions may take at most one parameter");

            alias values = GetAttributes!(module_, moduleMember, params[0]);

            import std.conv;
            static assert(values.length > 0,
                          text("Test functions with a parameter of type <", params[0].stringof,
                               "> must have value UDAs of the same type"));

            TestData[] testData;
            foreach(v; values)
                testData ~= memberTestData!(module_, moduleMember)(() { func(v); }, v.to!string);
            return testData;
        }
    } else static if(HasTypes!(mixin(moduleMember))) { //template function with @Types
        alias types = GetTypes!(mixin(moduleMember));
        TestData[] testData;
        foreach(type; types) {
            testData ~= memberTestData!(module_, moduleMember)(() {
                    mixin(moduleMember ~ `!(` ~ type.stringof ~ `)();`);
                }, type.stringof);
        }
        return testData;
    } else {
        return [];
    }
}



// this funtion returns TestData for either classes or test functions
// built-in unittest modules are handled by moduleUnitTests
// pred determines what qualifies as a test
// createTestData must return TestData[]
private TestData[] moduleTestData(alias module_, alias pred, alias createTestData)() pure {
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, module_)) {

        static if(PassesTestPred!(module_, pred, moduleMember))
            testData ~= createTestData!(module_, moduleMember);
    }

    return testData;

}

// TestData for a member of a module (either a test function or test class)
private TestData memberTestData(alias module_, string moduleMember)(TestFunction testFunction = null, string suffix = "") {
    //if there is a suffix, all tests sharing that suffix are single threaded with multiple values per "real" test
    //this is slightly hackish but works and actually makes sense - it causes unit_threaded.factory to make
    //a CompositeTestCase out of them
    immutable singleThreaded = HasAttribute!(module_, moduleMember, Serial) || suffix != "";
    enum builtin = false;
    enum tags = tagsFromAttrs!(GetAttributes!(module_, moduleMember, Tags));

    return TestData(fullyQualifiedName!module_~ "." ~ moduleMember,
                    testFunction,
                    HasAttribute!(module_, moduleMember, HiddenTest),
                    HasAttribute!(module_, moduleMember, ShouldFail),
                    singleThreaded,
                    builtin,
                    suffix,
                    tags);
}

string[] tagsFromAttrs(T...)() {
    static assert(T.length <= 1, "@Tags can only be applied once");
    static if(T.length)
        return T[0].values;
    else
        return [];
}

version(unittest) {

    import unit_threaded.tests.module_with_tests; //defines tests and non-tests
    import unit_threaded.asserts;
    import std.algorithm;
    import std.array;

    //helper function for the unittest blocks below
    private auto addModPrefix(string[] elements,
                              string module_ = "unit_threaded.tests.module_with_tests") nothrow {
        return elements.map!(a => module_ ~ "." ~ a).array;
    }
}

unittest {
    const expected = addModPrefix([ "FooTest", "BarTest", "Blergh"]);
    const actual = moduleTestClasses!(unit_threaded.tests.module_with_tests).
        map!(a => a.name).array;
    assertEqual(actual, expected);
}

unittest {
    const expected = addModPrefix([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr"]);
    const actual = moduleTestFunctions!(unit_threaded.tests.module_with_tests).
        map!(a => a.getPath).array;
    assertEqual(actual, expected);
}


unittest {
    const expected = addModPrefix(["unittest0", "unittest1", "myUnitTest"]);
    const actual = moduleUnitTests!(unit_threaded.tests.module_with_tests).
        map!(a => a.name).array;
    assertEqual(actual, expected);
}

version(unittest) {
    import unit_threaded.testcase: TestCase;
    private void assertFail(TestCase test, string file = __FILE__, ulong line = __LINE__) {
        import core.exception;
        import std.conv;

        try {
            test.silence;
            assert(test() != [], file ~ ":" ~ line.to!string ~ " Test was expected to fail but didn't");
            assert(false, file ~ ":" ~ line.to!string ~ " Expected test case " ~ test.getPath ~
                   " to fail with AssertError but it didn't");
        } catch(AssertError) {}
    }

    private void assertPass(TestCase test, string file = __FILE__, ulong line = __LINE__) {
        assertEqual(test(), [], file, line);
    }
}

@("Test that parametrized value tests work")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;

    const testData = allTestData!(unit_threaded.tests.parametrized).
        filter!(a => a.name.endsWith("testValues")).array;

    // there should only be on test case which is a composite of the 3 values in testValues
    auto composite = cast(CompositeTestCase)createTestCases(testData)[0];
    assert(composite !is null, "Wrong dynamic type for TestCase");
    auto tests = composite.tests;
    assertEqual(tests.length, 3);

    // the first and third test should pass, the second should fail
    assertPass(tests[0]);
    assertPass(tests[2]);

    assertFail(tests[1]);
}


@("Test that parametrized type tests work")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;

    const testData = allTestData!(unit_threaded.tests.parametrized).
        filter!(a => a.name.endsWith("testTypes")).array;
    const expected = addModPrefix(["testTypes.float", "testTypes.int"],
                                  "unit_threaded.tests.parametrized");
    const actual = testData.map!(a => a.getPath).array;
    assertEqual(actual, expected);

    // there should only be on test case which is a composite of the 2 testTypes
    auto composite = cast(CompositeTestCase)createTestCases(testData)[0];
    assert(composite !is null, "Wrong dynamic type for TestCase");
    auto tests = composite.tests;
    assertEqual(tests.map!(a => a.getPath).array, expected);

    assertPass(tests[1]);
    assertFail(tests[0]);
}

@("Test that value parametrized built-in unittest blocks work")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;

    const testData = allTestData!(unit_threaded.tests.parametrized).
        filter!(a => a.name.canFind("builtinIntValues")).array;

    // there should only be on test case which is a composite of the 4 values
    auto composite = cast(CompositeTestCase)createTestCases(testData)[0];
    assert(composite !is null, "Wrong dynamic type for TestCase");
    auto tests = composite.tests;
    assertEqual(tests.length, 4);

    // these should be ok
    assertPass(tests[1]);

    //these should fail
    assertFail(tests[0]);
    assertFail(tests[2]);
    assertFail(tests[3]);
}


@("Tests can be selected by tags") unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;

    const testData = allTestData!(unit_threaded.tests.tags).array;
    auto testsNoTags = createTestCases(testData);
    assertEqual(testsNoTags.length, 4);
    assertPass(testsNoTags[0]);
    assertFail(testsNoTags[1]);
    assertFail(testsNoTags[2]);
    assertFail(testsNoTags[3]);

    auto testsNinja = createTestCases(testData, ["@ninja"]);
    assertEqual(testsNinja.length, 1);
    assertPass(testsNinja[0]);

    auto testsMake = createTestCases(testData, ["@make"]);
    assertEqual(testsMake.length, 3);
    assertPass(testsMake.find!(a => a.getPath.canFind("testMake")).front);
    assertPass(testsMake.find!(a => a.getPath.canFind("unittest0")).front);
    assertFail(testsMake.find!(a => a.getPath.canFind("unittest2")).front);

    auto testsNotNinja = createTestCases(testData, ["~@ninja"]);
    assertEqual(testsNotNinja.length, 3);
    assertPass(testsNotNinja.find!(a => a.getPath.canFind("testMake")).front);
    assertFail(testsNotNinja.find!(a => a.getPath.canFind("unittest1")).front);
    assertFail(testsNotNinja.find!(a => a.getPath.canFind("unittest2")).front);
}
