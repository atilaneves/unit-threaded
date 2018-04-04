module unit_threaded.ut.reflection;

import unit_threaded.reflection;
import unit_threaded.ut.modules.module_with_tests; //defines tests and non-tests
import unit_threaded.asserts;
import std.algorithm;
import std.array;

//helper function for the unittest blocks below
private auto addModPrefix(string[] elements,
                          string module_ = "unit_threaded.ut.modules.module_with_tests") nothrow {
    return elements.map!(a => module_ ~ "." ~ a).array;
}


unittest {
    const expected = addModPrefix([ "FooTest", "BarTest", "Blergh", "Issue83"]);
    const actual = moduleTestClasses!(unit_threaded.ut.modules.module_with_tests).
        map!(a => a.name).array;
    assertEqual(actual, expected);
}

unittest {
    const expected = addModPrefix([ "testFoo", "testBar", "funcThatShouldShowUpCosOfAttr"]);
    const actual = moduleTestFunctions!(unit_threaded.ut.modules.module_with_tests).
        map!(a => a.getPath).array;
    assertEqual(actual, expected);
}


unittest {
    const expected = addModPrefix(["unittest0", "unittest1", "myUnitTest",
                                   "StructWithUnitTests.InStruct", "StructWithUnitTests.unittest1"]);
    const actual = moduleUnitTests!(unit_threaded.ut.modules.module_with_tests).
        map!(a => a.name).array;
    assertEqual(actual, expected);
}

version(unittest) {
    import unit_threaded.testcase: TestCase;
    private void assertFail(TestCase test, string file = __FILE__, size_t line = __LINE__) {
        import core.exception;
        import std.conv;

        test.silence;
        assert(test() != [],
               file ~ ":" ~ line.to!string ~ " Expected test case " ~ test.getPath ~
               " to fail but it didn't");
    }

    private void assertPass(TestCase test, string file = __FILE__, size_t line = __LINE__) {
        import unit_threaded.should: fail;
        if(test() != [])
            fail("'" ~ test.getPath ~ "' was expected to pass but failed", file, line);
    }
}

@("Test that parametrized value tests work")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.endsWith("testValues")).array;

    auto tests = createTestCases(testData);
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
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.endsWith("testTypes")).array;
    const expected = addModPrefix(["testTypes.float", "testTypes.int"],
                                  "unit_threaded.ut.modules.parametrized");
    const actual = testData.map!(a => a.getPath).array;
    assertEqual(actual, expected);

    auto tests = createTestCases(testData);
    assertEqual(tests.map!(a => a.getPath).array, expected);

    assertPass(tests[1]);
    assertFail(tests[0]);
}

@("Value parametrized built-in unittests")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("builtinIntValues")).array;

    auto tests = createTestCases(testData);
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
    import unit_threaded.ut.modules.tags;

    const testData = allTestData!(unit_threaded.ut.modules.tags).array;
    auto testsNoTags = createTestCases(testData);
    assertEqual(testsNoTags.length, 4);
    assertPass(testsNoTags[0]);
    assertFail(testsNoTags.find!(a => a.getPath.canFind("unittest1")).front);
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

    assertEqual(createTestCases(testData, ["unit_threaded.ut.modules.tags.testMake", "@ninja"]).length, 0);
}

@("Parametrized built-in tests with @AutoTags get tagged by value")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("builtinIntValues")).array;

    auto two = createTestCases(testData, ["@2"]);

    assertEqual(two.length, 1);
    assertFail(two[0]);

    auto three = createTestCases(testData, ["@3"]);
    assertEqual(three.length, 1);
    assertPass(three[0]);
}

@("Value parametrized function tests with @AutoTags get tagged by value")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("testValues")).array;

    auto two = createTestCases(testData, ["@2"]);
    assertEqual(two.length, 1);
    assertFail(two[0]);
}

@("Type parameterized tests with @AutoTags get tagged by type")
unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.ut.modules.parametrized;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("testTypes")).array;

    auto tests = createTestCases(testData, ["@int"]);
    assertEqual(tests.length, 1);
    assertPass(tests[0]);
}

@("Cartesian parameterized built-in values") unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.should: shouldBeSameSetAs;
    import unit_threaded.ut.modules.parametrized;
    import unit_threaded.attrs: getValue;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("cartesianBuiltinNoAutoTags")).array;

    auto tests = createTestCases(testData);
    tests.map!(a => a.getPath).array.shouldBeSameSetAs(
                addModPrefix(["foo.red", "foo.blue", "foo.green", "bar.red", "bar.blue", "bar.green"].
                             map!(a => "cartesianBuiltinNoAutoTags." ~ a).array,
                             "unit_threaded.ut.modules.parametrized"));
    assertEqual(tests.length, 6);

    auto fooRed = tests.find!(a => a.getPath.canFind("foo.red")).front;
    assertPass(fooRed);
    assertEqual(getValue!(string, 0), "foo");
    assertEqual(getValue!(string, 1), "red");
    assertEqual(testData.find!(a => a.getPath.canFind("foo.red")).front.tags, []);

    auto barGreen = tests.find!(a => a.getPath.canFind("bar.green")).front;
    assertFail(barGreen);
    assertEqual(getValue!(string, 0), "bar");
    assertEqual(getValue!(string, 1), "green");

    assertEqual(testData.find!(a => a.getPath.canFind("bar.green")).front.tags, []);
    assertEqual(allTestData!(unit_threaded.ut.modules.parametrized).
                filter!(a => a.name.canFind("cartesianBuiltinAutoTags")).array.
                find!(a => a.getPath.canFind("bar.green")).front.tags,
                ["bar", "green"]);
}

@("Cartesian parameterized function values") unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;
    import unit_threaded.should: shouldBeSameSetAs;

    const testData = allTestData!(unit_threaded.ut.modules.parametrized).
        filter!(a => a.name.canFind("CartesianFunction")).array;

    auto tests = createTestCases(testData);
        tests.map!(a => a.getPath).array.shouldBeSameSetAs(
            addModPrefix(["1.foo", "1.bar", "2.foo", "2.bar", "3.foo", "3.bar"].
                             map!(a => "testCartesianFunction." ~ a).array,
                             "unit_threaded.ut.modules.parametrized"));

    foreach(test; tests) {
        test.getPath.canFind("2.bar")
            ? assertPass(test)
            : assertFail(test);
    }

    assertEqual(testData.find!(a => a.getPath.canFind("2.bar")).front.tags,
                ["2", "bar"]);

}

@("module setup and shutdown")
unittest {
    import unit_threaded.testcase;
    import unit_threaded.factory;
    import unit_threaded.ut.modules.module_with_setup: gNumBefore, gNumAfter;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_setup".array;
    auto tests = createTestCases(testData);
    assertEqual(tests.length, 2);

    assertPass(tests[0]);
    assertEqual(gNumBefore, 1);
    assertEqual(gNumAfter, 1);

    assertFail(tests[1]);
    assertEqual(gNumBefore, 2);
    assertEqual(gNumAfter, 2);
}

@("issue 33") unittest {
    import unit_threaded.factory;
    import unit_threaded.testcase;

    const testData = allTestData!"unit_threaded.ut.modules.issue33";
    assertEqual(testData.length, 1);
}

@("issue 43") unittest {
    import unit_threaded.factory;
    import unit_threaded.asserts;
    import unit_threaded.ut.modules.module_with_tests;
    import std.algorithm: canFind;
    import std.array: array;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_tests";
    assertEqual(testData.canFind!(a => a.getPath.canFind("InStruct" )), true);
    auto inStructTest = testData
        .find!(a => a.getPath.canFind("InStruct"))
        .array
        .createTestCases[0];
    assertFail(inStructTest);
}

@("@DontTest should work for unittest blocks") unittest {
    import unit_threaded.factory;
    import unit_threaded.asserts;
    import unit_threaded.ut.modules.module_with_tests;
    import std.algorithm: canFind;
    import std.array: array;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_attrs";
    assertEqual(testData.canFind!(a => a.getPath.canFind("DontTestBlock" )), false);
}

@("@ShouldFail") unittest {
    import unit_threaded.factory;
    import unit_threaded.asserts;
    import unit_threaded.ut.modules.module_with_tests;
    import std.algorithm: find, canFind;
    import std.array: array;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_attrs";

    auto willFail = testData
        .filter!(a => a.getPath.canFind("will fail"))
        .array
        .createTestCases[0];
    assertPass(willFail);
}


@("@ShouldFailWith") unittest {
    import unit_threaded.factory;
    import unit_threaded.asserts;
    import unit_threaded.ut.modules.module_with_attrs;
    import std.algorithm: find, canFind;
    import std.array: array;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_attrs";

    auto doesntFail = testData
        .filter!(a => a.getPath.canFind("ShouldFailWith that fails due to not failing"))
        .array
        .createTestCases[0];
    assertFail(doesntFail);

    auto wrongType = testData
        .find!(a => a.getPath.canFind("ShouldFailWith that fails due to wrong type"))
        .array
        .createTestCases[0];
    assertFail(wrongType);

   auto passes = testData
        .find!(a => a.getPath.canFind("ShouldFailWith that passes"))
        .array
        .createTestCases[0];
    assertPass(passes);
}

@("structs are not classes") unittest {
    import unit_threaded.should;
    import unit_threaded.ut.modules.structs_are_not_classes;
    const testData = allTestData!"unit_threaded.ut.modules.structs_are_not_classes";
    testData.shouldBeEmpty;
}

@("@Flaky") unittest {
    import unit_threaded.factory;
    import unit_threaded.asserts;
    import unit_threaded.ut.modules.module_with_attrs;
    import std.algorithm: find, canFind;
    import std.array: array;

    const testData = allTestData!"unit_threaded.ut.modules.module_with_attrs";

    auto flakyPasses = testData
        .filter!(a => a.getPath.canFind("flaky that passes eventually"))
        .array
        .createTestCases[0];
    assertPass(flakyPasses);

    auto flakyFails = testData
        .filter!(a => a.getPath.canFind("flaky that fails due to not enough retries"))
        .array
        .createTestCases[0];
    assertFail(flakyFails);
}
