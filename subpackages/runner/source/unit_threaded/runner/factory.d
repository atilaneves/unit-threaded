/**
   Creates test cases from compile-time information.
 */
module unit_threaded.runner.factory;

import unit_threaded.from;
import unit_threaded.runner.testcase: CompositeTestCase;


private CompositeTestCase[string] serialComposites;

/**
 * Creates tests cases from the given modules.
 * If testsToRun is empty, it means run all tests.
 */
from!"unit_threaded.runner.testcase".TestCase[] createTestCases(
    in from!"unit_threaded.runner.reflection".TestData[] testData,
    in string[] testsToRun = [])
{
    import unit_threaded.runner.testcase: TestCase;
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


from!"unit_threaded.runner.testcase".TestCase createTestCase(
    in from!"unit_threaded.runner.reflection".TestData testData)
{
    import unit_threaded.runner.testcase: TestCase;
    import std.algorithm: splitter, reduce;
    import std.array: array;

    TestCase createImpl() {
        import unit_threaded.runner.testcase:
            BuiltinTestCase, FunctionTestCase, ShouldFailTestCase, FlakyTestCase;
        import std.conv: text;

        TestCase testCase = testData.builtin
            ? new BuiltinTestCase(testData)
            : new FunctionTestCase(testData);

        version(unitThreadedLight) {}
        else
            assert(testCase !is null,
                   text("Error creating test case with data: ", testData));

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



bool isWantedTest(in from!"unit_threaded.runner.reflection".TestData testData,
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

private bool isWantedNonTagTest(in from!"unit_threaded.runner.reflection".TestData testData,
                                in string[] testsToRun)
{

    import std.algorithm: any, startsWith, canFind;

    if(!testsToRun.length) return !testData.hidden; // all tests except the hidden ones

    bool matchesExactly(in string t) {
        return t == testData.getPath;
    }

    bool matchesPackage(in string t) { //runs all tests in package if it matches
        with(testData)
            return !hidden && getPath.length > t.length &&
                           getPath.startsWith(t) && getPath[t.length .. $].canFind(".");
    }

    return testsToRun.any!(a => matchesExactly(a) || matchesPackage(a));
}
