module ut.runner;

import ut.factory;
import ut.testsuite;
import ut.list;

import std.stdio;


void runTests(MODULES...)() {

    auto suite = TestSuite(createTests!MODULES());
    immutable elapsed = suite.run();

    writefln("Time taken: %.3f seconds", elapsed);
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");
}
