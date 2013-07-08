module ut.runner;

import ut.factory;
import ut.testsuite;
import ut.list;

import std.stdio;


void runTests(MODULES...)() {

    auto suite = TestSuite(createTests!MODULES());
    immutable elapsed = suite.run();

    writeln("Time taken: ", elapsed, " seconds");
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");
}
