module unit_threaded.factory;

import unit_threaded.testcase;
import unit_threaded.list;
import unit_threaded.asserts;
import unit_threaded.check;

import std.stdio;
import std.traits;
import std.typetuple;
import std.exception;
import std.algorithm;
import std.array;
import std.string;
import core.runtime;

/**
 * Replace the D runtime's normal unittest block tester with our own
 */
shared static this() {
    Runtime.moduleUnitTester = &moduleUnitTester;
}

/**
 * Creates tests cases from the given modules.
 * If testsToRun is empty, it means run all tests.
 */
TestCase[] createTests(in TestData[] testData, in string[] testsToRun = []) {
    bool[TestCase] tests;
    foreach(const data; testData) {
        if(!isWantedTest(data, testsToRun)) continue;
        auto test = createTestCase(data);
        if(test !is null) tests[test] = true; //can be null if abtract base class
    }

    return tests.keys.sort!((a, b) => a.getPath < b.getPath).array;
}


private TestCase createTestCase(TestData data) {
    TestCase createImpl(TestData data) {
        if(data.test is null) return cast(TestCase) Object.factory(data.name);
        return data.builtin ? new BuiltinTestCase(data) : new FunctionTestCase(data);
    }

    if(data.singleThreaded) {
        static CompositeTestCase[string] composites;
        const moduleName = getModuleName(data.name);
        if(moduleName !in composites) composites[moduleName] = new CompositeTestCase;
        composites[moduleName] ~= createImpl(data);
        return composites[moduleName];
    }

    if(data.shouldFail) {
        return new ShouldFailTestCase(createImpl(data));
    }

    auto testCase = createImpl(data);
    if(data.test !is null) {
        assert(testCase !is null, "Could not create TestCase object for test " ~ data.name);
    }

    return testCase;
}

private string getModuleName(in string name) {
    return name.splitter(".").array[0 .. $ - 1].reduce!((a, b) => a ~ "." ~ b);
}


private bool isWantedTest(in TestData data, in string[] testsToRun) {
    if(!testsToRun.length) return !data.hidden; //all tests except the hidden ones
    bool matchesExactly(in string t) { return t == data.name; }
    bool matchesPackage(in string t) { //runs all tests in package if it matches
        with(data) return !hidden && name.length > t.length &&
                       name.startsWith(t) && name[t.length .. $].canFind(".");
    }
    return testsToRun.any!(t => matchesExactly(t) || matchesPackage(t));
}


package const(TestData)[] getAllTestCaseData(MODULES...)() {
    auto getAllTestsWithFunc(string expr, MODULES...)() pure nothrow {
        //tests is whatever type expr returns
        ReturnType!(mixin(expr ~ q{!(MODULES[0])})) tests;
        foreach(mod; TypeTuple!MODULES) {
            tests ~= mixin(expr ~ q{!mod()}); //e.g. tests ~= getTestClasses!mod
        }
        return assumeUnique(tests);
    }

    return getAllTestsWithFunc!(q{getTestClasses}, MODULES) ~
           getAllTestsWithFunc!(q{getTestFunctions}, MODULES) ~
           getAllTestsWithFunc!(q{getBuiltinTests}, MODULES);
}


private bool moduleUnitTester() {
    //this is so unit-threaded's own tests run
    foreach(mod; ModuleInfo) {
        if(mod && mod.unitTest) {
            if(startsWith(mod.name, "unit_threaded.")) {
                mod.unitTest()();
            }
        }
    }

    return true;
}


unittest {
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
    assert(!isWantedTest(TestData("tests.pass.attributes.testHidden", true /*hidden*/), ["tests.pass"]));
}



unittest {
    import unit_threaded.asserts;
    assertEqual(getModuleName("tests.fail.composite.Test1"), "tests.fail.composite");
}
