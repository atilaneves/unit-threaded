#!/usr/bin/rdmd -unittest

import unit_threaded.runner;

//these must all be imported in order to be used as a symbol
import tests.pass.normal;
import tests.pass.delayed;
import tests.pass.attributes;
import tests.pass.register;
import tests.pass.io;
import tests.pass.fixtures;

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
        tests.pass.property,
        );
}
