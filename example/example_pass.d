#!/usr/bin/rdmd -unitest

import unit_threaded.runner;
import pass_tests;
import opts;

import std.stdio;


int main(string[] args) {
    writeln("Running passing unit-threaded examples...\n");
    immutable options = getOptions(args);
    immutable success = runTests!(pass_tests)(options.multiThreaded, options.tests);
    return success ? 0 : 1;
}
