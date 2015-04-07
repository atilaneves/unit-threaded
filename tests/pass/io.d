module tests.pass.io;

import unit_threaded;


@Name("testNoIo1") unittest {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
    writelnUt("But this should show up when using -d option");
}


@Name("testNoIo2") unittest {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}

@Name("testNoIo3") unittest {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}
