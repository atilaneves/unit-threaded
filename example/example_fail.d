#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import unit_threaded.options;
import std.stdio;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    //fail_tests and pass_tests are two modules in this directory
    immutable success = runTests!("fail_tests", "pass_tests")(getOptions(args));
    return success ? 0 : 1;
}
