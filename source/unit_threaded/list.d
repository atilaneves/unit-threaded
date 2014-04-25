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

/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
auto getTestClassNames(alias mod)() pure nothrow {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestData[] classes;

    foreach(klass; __traits(allMembers, mod)) {

        enum notPrivate = __traits(compiles, mixin(klass)); //only way I know to check if private
        enum compiles = __traits(compiles, isAggregateType!(mixin(klass)));

        static if(notPrivate && compiles) {

            enum isAggregate = isAggregateType!(mixin(klass));

            static if(isAggregate) {
                enum hasDontTest = HasAttribute!(mod, klass, DontTest);
                enum hasUnitTest = HasAttribute!(mod, klass, UnitTest);
                enum hasTestMethod = __traits(hasMember, mixin(klass), "test");

                static if(!hasDontTest && (hasTestMethod || hasUnitTest)) {
                    classes ~= TestData(fullyQualifiedName!mod ~ "." ~ klass,
                                        HasHidden!(mod, klass),
                                        HasShouldFail!(mod, klass),
                                        null, //TestFunction
                                        HasAttribute!(mod, klass, SingleThreaded));
                }
            }
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

        enum notPrivate = __traits(compiles, mixin(moduleMember));
        enum compiles = __traits(compiles, HasAttribute!(mod, moduleMember, DontTest));

        static if(notPrivate && compiles) {

            enum hasDontTest = HasAttribute!(mod, moduleMember, DontTest);
            enum hasUnitTest = HasAttribute!(mod, moduleMember, UnitTest);
            enum isFunction = isSomeFunction!(mixin(moduleMember));

            static if(!hasDontTest &&
                      (IsTestFunction!(mod, moduleMember) || (isFunction && hasUnitTest))) {

                enum funcName = fullyQualifiedName!mod ~ "." ~ moduleMember;
                enum funcAddr = "&" ~ funcName;

                functions ~= TestData(funcName ,
                                      HasHidden!(mod, moduleMember),
                                      HasShouldFail!(mod, moduleMember),
                                      &__traits(getMember, mod, moduleMember),
                                      HasAttribute!(mod, moduleMember, SingleThreaded));
            }
        }
    }

    return functions;
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
    const actual = array(map!(a => a.name)(getTestClassNames!(unit_threaded.tests.module_with_tests)()));
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
