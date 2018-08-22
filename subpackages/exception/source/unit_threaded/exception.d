/**
   Exception classes
 */
module unit_threaded.exception;

void fail(in string output, in string file, in size_t line) @safe pure
{
    throw new UnitTestException([output], file, line);
}

void fail(in string[] lines, in string file, in size_t line) @safe pure
{
    throw new UnitTestException(lines, file, line);
}

/**
 * An exception to signal that a test case has failed.
 */
class UnitTestException : Exception
{
    this(in string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        this([msg], file, line, next);
    }

    this(in string[] msgLines, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        import std.string: join;
        super(msgLines.join("\n"), next, file, line);
        this.msgLines = msgLines;
    }

    override string toString() @safe const pure scope
    {
        import std.algorithm: map;
        import std.array: join;
        return () @trusted { return msgLines.map!(a => getOutputPrefix(file, line) ~ a).join("\n"); }();
    }

private:

    const string[] msgLines;

    string getOutputPrefix(in string file, in size_t line) @safe const pure
    {
        import std.conv: to;
        return "    " ~ file ~ ":" ~ line.to!string ~ " - ";
    }
}
