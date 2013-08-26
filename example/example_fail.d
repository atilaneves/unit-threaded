#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Running failing unit-threaded examples...\n");
    //no import needed, passing them as strings
    return runTests!("example.tests.fail_tests", "example.tests.pass_tests")(args);
}
