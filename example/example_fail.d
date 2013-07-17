#!/usr/bin/rdmd -unittest

import ut.runner;

import std.stdio;


int main() {
    writeln("Running failing unit-threaded examples...\n");
    immutable success = runTests!("fail_tests", "pass_tests")();
    return success ? 0 : 1;
}
