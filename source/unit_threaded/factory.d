/**
   Creates test cases from compile-time information.
 */
module unit_threaded.factory;

import unit_threaded.from;
import unit_threaded.testcase: CompositeTestCase;


private CompositeTestCase[string] serialComposites;

/**
 * Creates tests cases from the given modules.
 * If testsToRun is empty, it means run all tests.
 */
from!"unit_threaded.testcase".TestCase[] createTestCases(
    in from!"unit_threaded.reflection".TestData[] testData,
    in string[] testsToRun = [])
{
    import unit_threaded.testcase: TestCase;
    import std.algorithm: sort;
    import std.array: array;

    serialComposites = null;
    bool[TestCase] tests;
    foreach(const data; testData) {
        if(!isWantedTest(data, testsToRun)) continue;
        auto test = createTestCase(data);
         if(test !is null) tests[test] = true; //can be null if abtract base class
    }

    return tests.keys.sort!((a, b) => a.getPath < b.getPath).array;
}


package from!"unit_threaded.testcase".TestCase createTestCase(
    in from!"unit_threaded.reflection".TestData testData)
{
    import unit_threaded.testcase: TestCase;
    import std.algorithm: splitter, reduce;
    import std.array: array;

    TestCase createImpl() {
        import unit_threaded.testcase:
            BuiltinTestCase, FunctionTestCase, ShouldFailTestCase, FlakyTestCase;
        import std.conv: text;

        TestCase testCase;

        if(testData.isTestClass)
            testCase = cast(TestCase) Object.factory(testData.name);
         else
            testCase = testData.builtin
                ? new BuiltinTestCase(testData)
                : new FunctionTestCase(testData);

        version(unitThreadedLight) {}
        else
            assert(testCase !is null,
                   text("Error creating test case with ",
                        testData.isTestClass ? "test class data: " : "data: ",
                        testData));

        if(testData.shouldFail) {
            testCase = new ShouldFailTestCase(testCase, testData.exceptionTypeInfo);
        } else if(testData.flakyRetries > 0)
            testCase = new FlakyTestCase(testCase, testData.flakyRetries);

        return testCase;
    }

    auto testCase = createImpl();

    if(testData.singleThreaded) {
        // @Serial tests in the same module run sequentially.
        // A CompositeTestCase is created for each module with at least
        // one @Serial test and subsequent @Serial tests
        // appended to it
        //const moduleName = testData.name.dup.splitter(".")
        const moduleName = testData.name.splitter(".")
            .array[0 .. $ - 1].
            reduce!((a, b) => a ~ "." ~ b);

        // create one if not already there
        if(moduleName !in serialComposites) {
            serialComposites[moduleName] = new CompositeTestCase;
        }

        // add the current test to the composite
        serialComposites[moduleName] ~= testCase;
        return serialComposites[moduleName];
    }

    assert(testCase !is null || testData.testFunction is null,
           "Could not create TestCase object for test " ~ testData.name);

    return testCase;
}



private bool isWantedTest(in from!"unit_threaded.reflection".TestData testData,
                          in string[] testsToRun)
{

    import std.algorithm: filter, all, startsWith, canFind;
    import std.array: array;

    bool isTag(in string t) { return t.startsWith("@") || t.startsWith("~@"); }

    auto normalToRun = testsToRun.filter!(a => !isTag(a)).array;
    auto tagsToRun = testsToRun.filter!isTag;

    bool matchesTags(in string tag) { //runs all tests with the specified tags
        assert(isTag(tag));
        return tag[0] == '@' && testData.tags.canFind(tag[1..$]) ||
            (!testData.hidden && tag.startsWith("~@") && !testData.tags.canFind(tag[2..$]));
    }

    return isWantedNonTagTest(testData, normalToRun) &&
        (tagsToRun.empty || tagsToRun.all!(t => matchesTags(t)));
}

private bool isWantedNonTagTest(in from!"unit_threaded.reflection".TestData testData,
                                in string[] testsToRun)
{

    import std.algorithm: any, startsWith, canFind;

    if(!testsToRun.length) return !testData.hidden; //all tests except the hidden ones

    bool matchesExactly(in string t) {
        return t == testData.name;
    }

    bool matchesPackage(in string t) { //runs all tests in package if it matches
        with(testData) return !hidden && name.length > t.length &&
                           name.startsWith(t) && name[t.length .. $].canFind(".");
    }

    return testsToRun.any!(a => matchesExactly(a) || matchesPackage(a));
}


unittest {
    import unit_threaded.reflection: TestData;
    //existing, wanted
    assert(isWantedTest(TestData("tests.server.testSubscribe"), ["tests"]));
    assert(isWantedTest(TestData("tests.server.testSubscribe"), ["tests."]));
    assert(isWantedTest(TestData("tests.server.testSubscribe"), ["tests.server.testSubscribe"]));
    assert(!isWantedTest(TestData("tests.server.testSubscribe"), ["tests.server.testSubscribeWithMessage"]));
    assert(!isWantedTest(TestData("tests.stream.testMqttInTwoPackets"), ["tests.server"]));
    assert(isWantedTest(TestData("tests.server.testSubscribe"), ["tests.server"]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests"]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests.testEqual"]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), []));
    assert(!isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests.foo"]));
    assert(!isWantedTest(TestData("example.tests.pass.normal.unittest"),
                         ["example.tests.pass.io.TestFoo"]));
    assert(isWantedTest(TestData("example.tests.pass.normal.unittest"), []));
    assert(!isWantedTest(TestData("tests.pass.attributes.testHidden", null, true /*hidden*/), ["tests.pass"]));
    assert(!isWantedTest(TestData("", null, false /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                  false /*builtin*/, "" /*suffix*/),
                         ["@foo"]));
    assert(isWantedTest(TestData("", null, false /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                 false /*builtin*/, "" /*suffix*/, ["foo"]),
                        ["@foo"]));

    assert(!isWantedTest(TestData("", null, false /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                 false /*builtin*/, "" /*suffix*/, ["foo"]),
                        ["~@foo"]));

    assert(isWantedTest(TestData("", null, false /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                  false /*builtin*/, "" /*suffix*/),
                         ["~@foo"]));

    assert(isWantedTest(TestData("", null, false /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                 false /*builtin*/, "" /*suffix*/, ["bar"]),
                         ["~@foo"]));

    // if hidden, don't run by default
    assert(!isWantedTest(TestData("", null, true /*hidden*/, false /*shouldFail*/, false /*singleThreaded*/,
                                  false /*builtin*/, "" /*suffix*/, ["bar"]),
                        ["~@foo"]));


}
