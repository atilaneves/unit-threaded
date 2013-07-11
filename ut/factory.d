module ut.factory;

import ut.testcase;
import ut.list;
import std.stdio;
import std.traits;
import std.typetuple;
import std.exception;

/**
 * Creates tests cases from the given modules
 */
TestCase[] createTests(MODULES...)() if(MODULES.length > 0) {
    TestCase[] tests;
    foreach(name; getAllTests!(q{getTestClassNames}, MODULES)()) {
        auto test = cast(TestCase) Object.factory(name);
        assert(test !is null, "Could not create object of type " ~ name);
        tests ~= test;
    }

    foreach(func; getAllTests!(q{getTestFunctions}, MODULES)()) {
        tests ~= new FunctionTestCase!(func.stringof, func)();
    }

    return tests;
}

private class FunctionTestCase(string funcName, alias func): TestCase {
    override void test() {
        func();
    }

    override string getPath() {
        return funcName;
    }
}

private auto getAllTests(string expr, MODULES...)() {
    //tests is whatever type expr returns
    ReturnType!(mixin(expr ~ q{!(MODULES[0])})) tests;
    foreach(mod; TypeTuple!MODULES) {
        tests ~= mixin(expr ~ q{!mod()});
    }
    return assumeUnique(tests);
}
