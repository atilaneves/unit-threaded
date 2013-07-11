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
TestCase[] createTests(MODULES...)() {
    TestCase[] tests;
    foreach(name; getAllTests!(string, q{getTestClassNames}, MODULES)()) {
        auto test = cast(TestCase) Object.factory(name);
        assert(test !is null, "Could not create object of type " ~ name);
        tests ~= test;
    }

    foreach(func; getAllTestFunctions!MODULES()) {
        tests ~= new FunctionTestCase!func();
    }

    return tests;
}

private class FunctionTestCase(alias func): TestCase {
    override void test() {
        func();
    }
}

private auto getAllTests(T, string expr, MODULES...)() {
    T[] tests;
    foreach(mod; TypeTuple!MODULES) {
        tests ~= mixin(expr ~ q{!mod()});
    }
    return assumeUnique(tests);
}

private auto getAllTestFunctions(MODULES...)() {
    void function()[] functions;
    foreach(mod; TypeTuple!MODULES) {
        functions ~= getTestFunctions!mod();
    }
    return assumeUnique(functions);
}
