#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import pass_tests; ///must be imported to be used as a symbol

import std.stdio;


int main(string[] args) {
    writeln("Running passing unit-threaded examples...\n");
    return runTests!(pass_tests)(args);
}
