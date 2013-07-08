#!/usr/bin/rdmd

import ut.testcase;
import ut.testsuite;
import std.stdio;
import std.conv;

class Foo: TestCase {
    override void test() {
        assertTrue(5 == 3);
        assertFalse(5 == 5);
        assertEqual(5, 5);
        assertNotEqual(5, 3);
        assertEqual(5, 3);
    }
}



void listTestClasses(alias mod)() {
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            writeln("class: ", klass);
            foreach(member; __traits(allMembers, mixin(klass))) {
            }
        }
    }
}

string[] getTestClassNames(alias mod)() {
    string[] classes = [];
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            classes ~= klass;
        }
    }

    return classes;
}


void main() {
    writeln("Testing Unit Threaded code...");
    TestCase[] tests = [ new Foo ];
    auto suite = TestSuite(tests);
    immutable elapsed = suite.run();
    writeln("Time taken: ", elapsed, " seconds");
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");

    writeln("Test classes: ", getTestClassNames!(ut.testcase)());
    listTestClasses!(ut.testcase)();


    // // MoudleInfo is a magical thing in object.d,
    // // implicitly imported, that can loop over all
    // // modules in the program: user and library
    // foreach(mod; ModuleInfo) {
    //     // the localClasses member gives back
    //     // ClassInfo things that we can compare
    //     writeln("Module " ~ to!string(mod));
    //     foreach(cla; mod.localClasses) {
    //         // note: we could also check this
    //         // recursively and check
    //         // cla.interfaces as well as base
    //         writeln("Class " ~ to!string(cla));
    //     }
    // }
}
