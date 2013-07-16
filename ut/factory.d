module ut.factory;

import ut.testcase;
import ut.list;
import ut.asserts;

import std.stdio;
import std.traits;
import std.typetuple;
import std.exception;
import std.algorithm;
import core.runtime;

static this() {
    Runtime.moduleUnitTester = &moduleUnitTester;
}

/**
 * Creates tests cases from the given modules
 */
TestCase[] createTests(MODULES...)(in string[] testsToRun = []) if(MODULES.length > 0) {
    TestCase[] tests;
    foreach(name; getAllTests!(q{getTestClassNames}, MODULES)()) {
        if(!isWantedTest(name, testsToRun)) continue;
        auto test = cast(TestCase) Object.factory(name);
        assert(test !is null, "Could not create object of type " ~ name);
        tests ~= test;
    }

    foreach(i, func; getAllTests!(q{getTestFunctions}, MODULES)()) {
        if(!isWantedTest(func.name, testsToRun)) continue;
        import std.conv;
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

//private void function()[] builtinTests; //built-in unittest blocks
private TestCase[] builtinTests; //built-in unittest blocks

private bool moduleUnitTester() {
    foreach(mod; ModuleInfo) {
        if(mod && mod.unitTest) {
            if(startsWith(mod.name, "ut.")) {
                writeln("Calling unittestblock of " ~ mod.name);
                mod.unitTest()();
            } else {
                builtinTests ~= new FunctionTestCase(TestFunctionData(mod.name ~ ".unittest", mod.unitTest));
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
