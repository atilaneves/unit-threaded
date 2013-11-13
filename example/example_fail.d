#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Unit-threaded examples: Failing\n");
    //no import needed, passing them as strings
    return runTests!("example.tests.fail.normal",
                     "example.tests.fail.delayed",
                     "example.tests.fail.priv",
                     "example.tests.pass.normal",
                     "example.tests.pass.delayed",
                     "example.tests.pass.attributes",
                     "example.tests.pass.register",
                     "example.tests.pass.io")(args);
}
