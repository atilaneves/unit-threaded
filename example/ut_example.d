#!/usr/bin/rdmd -Iut

public import ut.testcase;
import ut.testsuite;
import ut.list;
import std.stdio;
import std.conv;
import example_tests;


void main() {
    writeln("Testing Unit Threaded code...");
    TestCase[] tests = [ cast(TestCase) new WrongTest(), new RightTest() ];
    auto suite = TestSuite(tests);
    immutable elapsed = suite.run();
    writeln("Time taken: ", elapsed, " seconds");
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");

    writeln("Test classes in example_tests: ", getTestClassNames!(example_tests)());
}
