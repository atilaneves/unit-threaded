module ut.factory;

import ut.testcase;
import ut.list;
import std.stdio;
import std.traits;
import std.typetuple;

/**
 * Creates tests cases from the given modules
 */
TestCase[] createTests(MODULES...)() {
    string[] testCaseNames;
    foreach(mod; TypeTuple!MODULES) {
        testCaseNames ~= getTestClassNames!mod();
    }

    TestCase[] tests;
    foreach(name; testCaseNames) {
        auto test = cast(TestCase) Object.factory(name);
        assert(test !is null, "Could not create object of type " ~ name);
        tests ~= test;

    }

    return tests;
}
