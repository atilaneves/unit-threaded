#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    ///fail_tests and pass_tests are two modules in this directory
    ///no import necessary at the top, passed in as strings
    return runTests!("tests.fail_tests", "tests.pass_tests")(args);
}
