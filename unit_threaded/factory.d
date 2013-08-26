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
    //Create all tests derived from TestCase
    foreach(name; getAllTests!(q{getTestClassNames}, MODULES)()) {
        if(!isWantedTest(name, testsToRun)) continue;
        auto test = cast(TestCase) Object.factory(name);
        if(test !is null) tests ~= test; //can be null if abtract base class
    }

    //Create all tests from testFoo() functions
    foreach(i, func; getAllTests!(q{getTestFunctions}, MODULES)()) {
        if(!isWantedTest(func.name, testsToRun)) continue;
        auto test = new FunctionTestCase(func);
        assert(test !is null, "Could not create FunctionTestCase object for function " ~ func.name);
        tests ~= test;
    }

    return tests ~ builtinTests;
}

private bool isWantedTest(in string testName, in string[] testsToRun) {
    if(!testsToRun.length) return true; //"all tests"
    foreach(testToRun; testsToRun) {
        if(startsWith(testName, testToRun)) return true;
    }
    return false;
}

private class FunctionTestCase: TestCase {
    this(immutable TestFunctionData func) pure nothrow {
        _name = func.name;
        _func = func.func;
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
    this(immutable TestFunctionData func) pure nothrow {
        super(func);
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
                builtinTests ~=
                    new BuiltinTestCase(TestFunctionData(mod.name ~ ".unittest", mod.unitTest));
            }
        }
    }

    return true;
}


unittest {
    assert(isWantedTest("pass_tests.testEqual", ["pass_tests"]));
    assert(isWantedTest("pass_tests.testEqual", ["pass_tests."]));
    assert(isWantedTest("pass_tests.testEqual", ["pass_tests.testEqual"]));
    assert(isWantedTest("pass_tests.testEqual", []));
    assert(!isWantedTest("pass_tests.testEqual", ["pass_tests.foo"]));
}
