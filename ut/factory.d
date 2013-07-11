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
    foreach(name; getAllTests!(q{getTestClassNames}, MODULES)()) {
        auto test = cast(TestCase) Object.factory(name);
        assert(test !is null, "Could not create object of type " ~ name);
        tests ~= test;
    }

    return tests;
}

private auto getAllTests(string expr, MODULES...)() {
    string[] functions;
    foreach(mod; TypeTuple!MODULES) {
        functions ~= mixin(expr ~ q{!mod()});
    }
    return assumeUnique(functions);
}
