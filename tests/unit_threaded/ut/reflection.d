module unit_threaded.ut.reflection;

import unit_threaded.runner.reflection;
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
    import std.algorithm: sorted = sort;

    const expected = addModPrefix(
        [
            "myUnitTest",
            "StructWithUnitTests.InStruct",
            "StructWithUnitTests.unittest_L58_C5",
            "unittest_L36",
            "unittest_L41",
        ]
    ).sorted.array;
    const actual = moduleUnitTests!(unit_threaded.ut.modules.module_with_tests).
        map!(a => a.name).array.sorted.array;

    assertEqual(actual, expected);
}


@safe pure unittest {
    import std.algorithm: sorted = sort;

    const actual = moduleUnitTests!(unit_threaded.ut.modules.issue225).
        map!(a => a.name).array;

    assertEqual(actual, ["unit_threaded.ut.modules.issue225.oops"]);
}


version(unittest) {
    import unit_threaded.runner.testcase: TestCase;
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


@("Tests can be selected by tags") unittest {
    import unit_threaded.runner.factory;
    import unit_threaded.runner.testcase;
    import unit_threaded.ut.modules.tags;

    const testData = allTestData!(unit_threaded.ut.modules.tags).array;
    auto testsNoTags = createTestCases(testData);
    assertEqual(testsNoTags.length, 3);
    assertPass(testsNoTags.find!(a => a.getPath.canFind("unittest_L6")).front);
    assertFail(testsNoTags.find!(a => a.getPath.canFind("unittest_L8")).front);
    assertFail(testsNoTags.find!(a => a.getPath.canFind("unittest_L14")).front);

    auto testsNinja = createTestCases(testData, ["@ninja"]);
    assertEqual(testsNinja.length, 1);
    assertPass(testsNinja[0]);

    auto testsMake = createTestCases(testData, ["@make"]);
    assertEqual(testsMake.length, 2);
    assertPass(testsMake.find!(a => a.getPath.canFind("unittest_L6")).front);
    assertFail(testsMake.find!(a => a.getPath.canFind("unittest_L14")).front);

    auto testsNotNinja = createTestCases(testData, ["~@ninja"]);
    assertEqual(testsNotNinja.length, 2);
    assertFail(testsNotNinja.find!(a => a.getPath.canFind("unittest_L8")).front);
    assertFail(testsNotNinja.find!(a => a.getPath.canFind("unittest_L14")).front);

    assertEqual(createTestCases(testData, ["unit_threaded.ut.modules.tags.testMake", "@ninja"]).length, 0);
}


@("module setup and shutdown")
unittest {
    import unit_threaded.runner.testcase;
    import unit_threaded.runner.factory;
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
    import unit_threaded.runner.factory;
    import unit_threaded.runner.testcase;

    const testData = allTestData!"unit_threaded.ut.modules.issue33";
    assertEqual(testData.length, 1);
}

@("issue 43") unittest {
    import unit_threaded.runner.factory;
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


@("@ShouldFail") unittest {
    import unit_threaded.runner.factory;
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
    import unit_threaded.runner.factory;
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
    import unit_threaded.runner.factory;
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
