module unit_threaded.asserts;

import std.conv;


void assertEqual(T, U)(T t, U u) {
    assert(t == u, "\nExp: " ~ to!string(u) ~ "\nGot: " ~ to!string(t));
}
