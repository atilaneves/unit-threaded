module tests.pass.io;

import unit_threaded;
import std.stdio;


@name("testNoIo1") unittest
{
    writeln("This should not be seen except for -d option");
    stderr.writeln("Stderr shouldn't be seen either");
    writelnUt("But this should show up when using -d option");
}

@name("testNoStdout") unittest
{
    writeln("This should not be seen except for -d option");
}

@name("testNoStderr") unittest
{
    stderr.writeln("Stderr shouldn't be seen either");
}

@name("testNoIo2") unittest
{
    writeln("This should not be seen except for -d option");
    stderr.writeln("Stderr shouldn't be seen either");
}
