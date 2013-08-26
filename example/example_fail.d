#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Unit-threaded examples: Failing\n");
    //no import needed, passing them as strings
    return runTests!("example.tests.fail_tests", "example.tests.pass_tests")(args);
}
