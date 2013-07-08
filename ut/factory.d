module ut.factory;

import ut.testcase;
import ut.list;
import std.stdio;
import std.traits;

/**
 * Creates tests cases from the given modules
 */
//TestCase[] createTests(MODULES...)() {
TestCase[] createTests(alias mod)() {
    // string[] testCaseNames;
    // foreach(mod; MODULES) {
    //     testCaseNames ~= getTestClassNames!mod();
    // }
    static testCaseNames = getTestClassNames!mod();
    writeln("tests: ", testCaseNames);
    TestCase[] tests;
    foreach(name; testCaseNames) {
        immutable fullName = fullyQualifiedName!mod ~ "." ~ name;
        auto test = cast(TestCase) Object.factory(fullName);
        assert(test !is null, "Could not create object of type " ~ fullName);
        tests ~= test;

    }

    return tests;
}
