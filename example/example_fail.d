#!/usr/bin/rdmd -unittest

import ut.runner;
import std.stdio;


int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    const tests = args[1..$];

    //fail_tests and pass_tests are two modules in this directory
    immutable success = runTests!("fail_tests", "pass_tests")(tests);
    return success ? 0 : 1;
}
