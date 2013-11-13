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
import std.string;
import core.runtime;

/**
 * Replace the D runtime's normal unittest block tester with our own
 */
static this() {
    Runtime.moduleUnitTester = &moduleUnitTester;
}

/**
 * Creates tests cases from the given modules.
 * If testsToRun is empty, it means run all tests.
 */
TestCase[] createTests(MODULES...)(in string[] testsToRun = []) if(MODULES.length > 0) {
    TestCase[] tests;
    foreach(data; getTestClassesAndFunctions!MODULES()) {
        if(!isWantedTest(data, testsToRun)) continue;
        auto test = createTestCase(data);
        if(test !is null) tests ~= test; //can be null if abtract base class
    }

    foreach(test; builtinTests) { //builtInTests defined below
        if(isWantedTest(test.getPath(), testsToRun)) tests ~= test;
    }

    return tests;
}

private TestCase createTestCase(TestData data) {
    auto testCase = data.test is null ?
        cast(TestCase) Object.factory(data.name):
        new FunctionTestCase(data);

    if(data.test !is null) {
        assert(testCase !is null, "Could not create FunctionTestCase object for function " ~ data.name);
    }

    return testCase;
}

private bool isWantedTest(in TestData data, in string[] testsToRun) {
    if(!testsToRun.length) return !data.hidden; //"all tests (except hidden)"
    return isWantedTest(data.name, testsToRun);
}

private bool isWantedTest(in string name, in string[] testsToRun) {
    if(!testsToRun.length) return true;
    foreach(testToRun; testsToRun) {
        if(startsWith(name, testToRun)) return true; //even if hidden
    }
    return false;
}

private class FunctionTestCase: TestCase {
    this(immutable TestData data) pure nothrow {
        _name = data.name;
        _func = data.test;
    }

    override void test() {
        _func();
    }

    override string getPath() const pure nothrow {
        return _name;
    }

    private string _name;
    private TestFunction _func;
}

package auto getTestClassesAndFunctions(MODULES...)() {
    return getAllTests!(q{getTestClassNames}, MODULES)() ~
           getAllTests!(q{getTestFunctions}, MODULES)();
}

private auto getAllTests(string expr, MODULES...)() pure nothrow {
    //tests is whatever type expr returns
    ReturnType!(mixin(expr ~ q{!(MODULES[0])})) tests;
    foreach(mod; TypeTuple!MODULES) {
        tests ~= mixin(expr ~ q{!mod()});
    }
    return assumeUnique(tests);
}


private TestCase[] builtinTests; //built-in unittest blocks

private class BuiltinTestCase: FunctionTestCase {
    this(immutable TestData data) pure nothrow {
        super(data);
    }

    override void test() {
        try {
            super.test();
        } catch(Throwable t) {
            utFail(t.msg, t.file, t.line);
        }
    }
}

private bool moduleUnitTester() {
    foreach(mod; ModuleInfo) {
        if(mod && mod.unitTest) {
            if(startsWith(mod.name, "unit_threaded.")) {
                mod.unitTest()();
            } else {
                enum hidden = false;
                builtinTests ~=
                    new BuiltinTestCase(TestData(mod.name ~ ".unittest", hidden, mod.unitTest));
            }
        }
    }

    return true;
}


unittest {
    assert(isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests"]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests."]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests.testEqual"]));
    assert(isWantedTest(TestData("pass_tests.testEqual"), []));
    assert(!isWantedTest(TestData("pass_tests.testEqual"), ["pass_tests.foo"]));
    assert(!isWantedTest("example.tests.pass.normal.unittest",
                         ["example.tests.pass.io.TestFoo"]));
    assert(isWantedTest("example.tests.pass.normal.unittest", []));
}
