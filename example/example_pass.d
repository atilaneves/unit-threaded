#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import example.tests.pass.normal; ///must be imported to be used as a symbol
import example.tests.pass.delayed; ///must be imported to be used as a symbol
import example.tests.pass.attributes; ///must be imported to be used as a symbol
import example.tests.pass.register; ///must be imported to be used as a symbol
import example.tests.pass.io; ///must be imported to be used as a symbol

import std.stdio;


int main(string[] args) {
    writeln("Unit-threaded examples: Passing\n");
    ///pass_tests is a modules in the tests directory
    ///no import necessary at the top, passed in as strings
    return runTests!(example.tests.pass.normal,
                     example.tests.pass.delayed,
                     example.tests.pass.attributes,
                     example.tests.pass.register,
                     example.tests.pass.io)(args);
}
