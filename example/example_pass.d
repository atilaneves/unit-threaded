#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import unit_threaded.options;
import pass_tests;

import std.stdio;


int main(string[] args) {
    writeln("Running passing unit-threaded examples...\n");
    immutable options = getOptions(args);
    immutable success = runTests!(pass_tests)(getOptions(args));
    return success ? 0 : 1;
}
