#!/usr/bin/rdmd -I.. -unittest

import unit_threaded.runner;
import std.stdio;
import opts;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    immutable options = getOptions(args);
    //fail_tests and pass_tests are two modules in this directory
    immutable success = runTests!("fail_tests", "pass_tests")(options.multiThreaded, options.tests);
    return success ? 0 : 1;
}
