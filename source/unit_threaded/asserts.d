/**
   Custom assertions for testing unit-threaded itself, not intended for the end-user.
 */
module unit_threaded.asserts;

@safe:

/**
 * Helper to call the standard assert
 */
void assertEqual(T, U)(T t, U u, string file = __FILE__, size_t line = __LINE__) @trusted /* std.conv.to */ {
    import std.conv: to;
    assert(t == u, "\n" ~ file ~ ":" ~ line.to!string ~ "\nExp: " ~ u.to!string ~ "\nGot: " ~ t.to!string);
}


void assertExceptionMsg(E)(lazy E expr, string expected,
                           in string file = __FILE__,
                           in size_t line = __LINE__)
{
    import unit_threaded.should: UnitTestException;
    import std.string: stripLeft, replace, split;
    import std.path: dirSeparator;
    import std.algorithm: map, all, endsWith;
    import std.range: zip;
    import std.conv: to, text;
    import core.exception: AssertError;

    string getExceptionMsg(E)(lazy E expr) {
        try
        {
            expr();
        }
        catch(UnitTestException ex)
        {
            return ex.toString;
        }
        assert(0, "Expression did not throw UnitTestException");
    }


    //updating the tests below as line numbers change is tedious.
    //instead, replace the number there with the actual line number
    expected = expected.replace(":123", ":" ~ line.to!string).replace("/", dirSeparator);
    auto msg = getExceptionMsg(expr);
    auto expLines = expected.split("\n").map!stripLeft;
    auto msgLines = msg.split("\n").map!stripLeft;
    if(!zip(msgLines, expLines).all!(a => a[0].endsWith(a[1]))) {
        throw new AssertError(text("\nExpected Exception:\n", expected, "\nGot Exception:\n", msg), file, line);
    }
}
