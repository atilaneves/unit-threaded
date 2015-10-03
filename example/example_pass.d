#!/usr/bin/rdmd -unittest

import unit_threaded.runner;
import tests.pass.normal; ///must be imported to be used as a symbol
import tests.pass.delayed; ///must be imported to be used as a symbol
import tests.pass.attributes; ///must be imported to be used as a symbol
import tests.pass.register; ///must be imported to be used as a symbol
import tests.pass.io; ///must be imported to be used as a symbol

import std.stdio;


int main(string[] args) {
    writeln("Unit-threaded examples: Passing\n");
    return args.runTests!(
        tests.pass.normal,
        tests.pass.delayed,
        tests.pass.attributes,
        tests.pass.register,
        tests.pass.io,
        tests.pass.fixtures,
        );
}
