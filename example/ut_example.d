#!/usr/bin/rdmd -Iut

import ut.runner;
import example_tests;
import more_example_tests;

import std.stdio;


void main() {
    writeln("Running unit-threaded examples...\n");
    runTests!(example_tests, more_example_tests)();
}
