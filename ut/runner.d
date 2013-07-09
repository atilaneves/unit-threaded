module ut.runner;

import ut.factory;
import ut.testsuite;

import std.stdio;


bool runTests(MODULES...)() {

    auto suite = TestSuite(createTests!MODULES());
    immutable elapsed = suite.run();

    writefln("Time taken: %.3f seconds", elapsed);
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");

    if(!suite.passed) {
        writeln("Unit tests failed!\n");
        return false; //oops
    }

    writeln("\nOK!\n");
    return true;
}
