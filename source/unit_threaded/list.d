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


private template HasHidden(alias mod, string member) {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    alias attrs = Filter!(isAHiddenStruct, __traits(getAttributes, mixin(member)));
    static assert(attrs.length == 0 || attrs.length == 1,
                  "Maximum number of HiddenTest attributes is 1");
    static if(attrs.length == 0) {
        //this is here to allow for HiddenTest without a string param
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
        //this is here to allow for ShouldFail without a string param
        enum HasShouldFail = false;
    } else {
        enum HasShouldFail = true;
    }
}


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
}


private auto createTestData(alias mod, string moduleMember)() pure nothrow {
    return TestData(fullyQualifiedName!mod ~ "." ~ moduleMember,
                    HasHidden!(mod, moduleMember),
                    HasShouldFail!(mod, moduleMember),
                    getTestFunction!(mod, moduleMember),
                    HasAttribute!(mod, moduleMember, SingleThreaded));
}

//returns a function pointer for test functions, null for test classes
private TestFunction getTestFunction(alias mod, string moduleMember)() {
    static if(__traits(compiles, &__traits(getMember, mod, moduleMember))) {
        return &__traits(getMember, mod, moduleMember);
    } else {
        return null;
    }
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

/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
auto getTestClasses(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, mod)) {

        enum notPrivate = __traits(compiles, mixin(moduleMember)); //only way I know to check if private

        static if(notPrivate && isTestClass!(mod, moduleMember)) {
            static if(!HasAttribute!(mod, moduleMember, DontTest)) {
                testData ~= createTestData!(mod, moduleMember);
            }
        }
    }

    return testData;
}

/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
auto getTestFunctions(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] testData;
    foreach(moduleMember; __traits(allMembers, mod)) {

        enum notPrivate = __traits(compiles, mixin(moduleMember));

        static if(notPrivate && isTestFunction!(mod, moduleMember)) {
            static if(!HasAttribute!(mod, moduleMember, DontTest)) {
                testData ~= createTestData!(mod, moduleMember);
            }
        }
    }

    return testData;
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
    const actual = array(map!(a => a.name)(getTestClasses!(unit_threaded.tests.module_with_tests)()));
    assertEqual(actual, expected);
}

unittest {
    static assert(hasTestPrefix!(unit_threaded.tests.module_with_tests, "testFoo"));
    static assert(!hasTestPrefix!(unit_threaded.tests.module_with_tests, "funcThatShouldShowUpCosOfAttr"));
}

unittest {
    import std.algorithm;
    import std.array;
    auto expected = addModule([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr" ]);
    auto actual = map!(a => a.name)(getTestFunctions!(unit_threaded.tests.module_with_tests)());
    assertEqual(array(actual), expected);
}
