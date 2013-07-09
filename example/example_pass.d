#!/usr/bin/rdmd -unittest

import ut.runner;
import pass_tests;

import std.stdio;


int main() {
    writeln("Running passing unit-threaded examples...\n");
    immutable success = runTests!(pass_tests)();
    return success ? 0 : 1;
}
