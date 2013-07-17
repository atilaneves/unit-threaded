#!/usr/bin/rdmd -unittest

import ut.runner;
import std.stdio;
import example.opts;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    immutable options = getOptions(args);
    const tests = options.args[1..$];
    //fail_tests and pass_tests are two modules in this directory
    immutable success = runTests!("fail_tests", "pass_tests")(options.multiThreaded, tests);
    return success ? 0 : 1;
}
