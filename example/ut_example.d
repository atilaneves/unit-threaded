#!/usr/bin/rdmd -Iut

public import ut.testcase;
import ut.testsuite;
import ut.list;
import ut.factory;
import std.stdio;
import std.conv;
import example_tests;


void main() {
    writeln("Testing Unit Threaded code...");

    auto suite = TestSuite(createTests!(example_tests)());
    immutable elapsed = suite.run();

    writeln("Time taken: ", elapsed, " seconds");
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");
}
