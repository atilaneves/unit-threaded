#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import example.tests.pass_tests; ///must be imported to be used as a symbol
import example.tests.fail_tests; ///must be imported to be used as a symbol
import std.stdio;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    return runTests!(example.tests.fail_tests, example.tests.pass_tests)(args);
}
