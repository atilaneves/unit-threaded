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

    foreach(i, func; getAllTests!(q{getTestFunctions}, MODULES)()) {
        import std.conv;
        auto test = new FunctionTestCase(func);
        assert(test !is null, "Could not create FunctionTestCase object");
        tests ~= test;
    }

    return tests;
}

private class FunctionTestCase: TestCase {
    this(immutable TestFunctionData func) {
        _name = func.name;
        _func = func.func;
    }

    override void test() {
        _func();
    }

    override string getPath() {
        return _name;
    }

    private string _name;
    private TestFunction _func;
}

private auto getAllTests(string expr, MODULES...)() {
    //tests is whatever type expr returns
    ReturnType!(mixin(expr ~ q{!(MODULES[0])})) tests;
    foreach(mod; TypeTuple!MODULES) {
        tests ~= mixin(expr ~ q{!mod()});
    }
    return assumeUnique(tests);
}
