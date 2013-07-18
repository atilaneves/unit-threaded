#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import tests.pass_tests; ///must be imported to be used as a symbol

import std.stdio;


int main(string[] args) {
    writeln("Running passing unit-threaded examples...\n");
    return runTests!(tests.pass_tests)(args);
}
