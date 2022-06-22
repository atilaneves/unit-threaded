/**
   Exception classes
 */
module unit_threaded.exception;

void fail(const string output, const string file, size_t line) @safe pure
{
    throw new UnitTestException([output], file, line);
}

void fail(const string[] lines, const string file, size_t line) @safe pure
{
    throw new UnitTestException(lines, file, line);
}

/**
 * An exception to signal that a test case has failed.
 */
public class UnitTestException : Exception
{
    mixin UnitTestFailureImpl;
}

public class UnitTestError : Error
{
    mixin UnitTestFailureImpl;
}

private template UnitTestFailureImpl()
{
    this(const string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        this([msg], file, line, next);
    }

    this(const string[] msgLines, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        import std.string: join;
        static if (is(typeof(this) : Exception))
        {
            super(msgLines.join("\n"), next, file.dup, line);
        }
        else
        {
            super(msgLines.join("\n"), file.dup, line, next);
        }
        this.msgLines = msgLines.dup;
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
