module ut.runner;

import ut.factory;
import ut.testsuite;
import ut.term;

import std.stdio;


bool runTests(MODULES...)() {

    auto suite = TestSuite(createTests!MODULES());
    immutable elapsed = suite.run();

    writefln("Time taken: %.3f seconds", elapsed);
    writeln(suite.numTestsRun, " test(s) run, ",
            suite.numFailures, " failed.\n");

    if(!suite.passed) {
        writelnRed("\nUnit tests failed!\n");
        return false; //oops
    }

    writelnGreen("\nOK!\n");
    return true;
}
