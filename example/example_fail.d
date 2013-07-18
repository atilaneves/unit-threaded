#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import unit_threaded.options;
import std.stdio;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    immutable options = getOptions(args);
    //fail_tests and pass_tests are two modules in this directory
    immutable success = runTests!("fail_tests", "pass_tests")(options.multiThreaded, options.tests);
    return success ? 0 : 1;
}
