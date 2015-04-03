module tests.pass.io;

import unit_threaded;


class TestIo: TestCase {
    override void test() {
        writelnUt("Class writelnUt should only print with '-d' option");
    }
}

void testNoIo1() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
    writelnUt("But this should show up when using -d option");
}


void testNoIo2() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}

void testNoIo3() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}
