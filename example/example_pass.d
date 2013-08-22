#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import example.tests.pass_tests; ///must be imported to be used as a symbol

import std.stdio;


int main(string[] args) {
    writeln("Running passing unit-threaded examples...\n");
    ///pass_tests is a modules in the tests directory
    ///no import necessary at the top, passed in as strings
    return runTests!(example.tests.pass_tests)(args);
}
