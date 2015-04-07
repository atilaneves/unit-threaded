#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("Unit-threaded examples: Failing\n");
    //no import needed, passing them as strings
    return args.runTests!(
        "tests.fail.normal",
        "tests.fail.delayed",
        "tests.fail.composite",
        "tests.fail.exception",
        "tests.pass.normal",
        "tests.pass.delayed",
        "tests.pass.attributes",
        "tests.pass.io");
}
