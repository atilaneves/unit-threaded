module unit_threaded.asserts;

import std.conv;

@safe:

/**
 * Helper to call the standard assert
 */
void assertEqual(T, U)(T t, U u) {
    assert(t == u, "\nExp: " ~ to!string(u) ~ "\nGot: " ~ to!string(t));
}
