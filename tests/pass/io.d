module tests.pass.io;

import unit_threaded;
import std.stdio;


@Name("testNoIo1") unittest
{
    writeln("This should not be seen except for -d option");
    stderr.writeln("Stderr shouldn't be seen either");
    writelnUt("But this should show up when using -d option");
}

@Name("testNoStdout") unittest
{
    writeln("This should not be seen except for -d option");
}

@Name("testNoStderr") unittest
{
    stderr.writeln("Stderr shouldn't be seen either");
}

@Name("testNoIo2") unittest
{
    writeln("This should not be seen except for -d option");
    stderr.writeln("Stderr shouldn't be seen either");
}
