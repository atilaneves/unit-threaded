#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Unit-threaded examples: Failing\n");
    //no import needed, passing them as strings
    return runTests!("tests.fail.normal",
                     "tests.fail.delayed",
                     "tests.fail.priv",
                     "tests.fail.composite",
                     "tests.pass.normal",
                     "tests.pass.delayed",
                     "tests.pass.attributes",
                     "tests.pass.register",
                     "tests.pass.io")(args);
}
