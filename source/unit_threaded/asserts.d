module unit_threaded.asserts;

import std.conv;

@safe:

/**
 * Helper to call the standard assert
 */
void assertEqual(T, U)(T t, U u, string file = __FILE__, ulong line = __LINE__) @trusted /* std.conv.to */ {
    assert(t == u, "\n" ~ file ~ ":" ~ line.to!string ~ "\nExp: " ~ u.to!string ~ "\nGot: " ~ t.to!string);
}
