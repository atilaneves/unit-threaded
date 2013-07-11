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

    static functions = getAllTestFunctions!MODULES();

    return tests;
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
        functions ~= getTestFunctionPointers!mod();
    }
    return assumeUnique(functions);
}
