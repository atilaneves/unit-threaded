/**
   Exception classes
 */
module unit_threaded.exception;

/**
 * What's the deal with `DelayedToString`?
 * `BuiltinTestCase` creates `UnitTestFailure` exceptions. Now we'd
 * ordinarily call `toString` to convert the caught exceptions to
 * a list of lines containing a backlog.
 * However, in a `ShouldFail` test, this exception is never printed.
 * So because converting a list of backtrace symbols to strings is
 * slow, this wastes a lot of time for no reason.
 * So we just create a `UnitTestException` that contains the
 * necessary information to generate the backtrace when `toString`
 * is actually called, which in a `ShouldFail` test is never.
 */

import std.sumtype;
import std.typecons;

noreturn fail(const string output, const string file, size_t line) @safe pure
{
    throw new UnitTestException([output], file, line);
}

noreturn fail(const string[] lines, const string file, size_t line) @safe pure
{
    throw new UnitTestException(lines, file, line);
}

package noreturn fail(Throwable throwable) @safe pure
{
    throw new UnitTestException(throwable);
}

package noreturn fail(Throwable throwable, Throwable.TraceInfo traceInfo, int removeExtraLines) @safe pure
{
    throw new UnitTestException(throwable, traceInfo, removeExtraLines);
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
    Nullable!DelayedToString delayedToString;

    this(const string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        this([msg], file, line, next);
    }

    package this(Throwable throwable) @safe pure nothrow
    {
        this([throwable.msg], throwable.file, throwable.line, throwable.next);
        this.delayedToString = DelayedToString(throwable);
    }

    package this(Throwable throwable, Throwable.TraceInfo localTraceInfo, int removeExtraLines) @safe pure nothrow
    {
        this([throwable.msg], throwable.file, throwable.line, throwable.next);
        this.delayedToString = DelayedToString(LocalStacktraceToString(
            throwable, localTraceInfo, removeExtraLines));
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

    override string toString() @trusted scope
    {
        import std.algorithm: map;
        import std.array: join;

        if (!this.delayedToString.isNull)
        {
            return this.delayedToString.get.match!(
                (Throwable throwable) => throwable.toString,
                // (Throwable throwable, Throwable.Traceinfo traceInfo, int removeExtraLines) in my dreams.
                (LocalStacktraceToString args) =>
                    args.throwable.localStacktraceToString(args.localTraceInfo, args.removeExtraLines),
            );
        }

        return msgLines.map!(a => getOutputPrefix(file, line) ~ a).join("\n");
    }

private:

    const string[] msgLines;

    string getOutputPrefix(in string file, in size_t line) @safe const pure scope
    {
        import std.conv: text;
        return text("    ", file, ":", line, " - ");
    }
}

private alias LocalStacktraceToString = Tuple!(
    Throwable, "throwable", Throwable.TraceInfo, "localTraceInfo", int, "removeExtraLines");

private alias DelayedToString = SumType!(Throwable, LocalStacktraceToString);

/**
 * Generate `toString` text for a `Throwable` that contains just the stack trace
 * below the location represented by `localTraceInfo`, plus some additional number of trace lines.
 *
 * Used to generate a backtrace that cuts off exactly at a unittest body.
 */
private string localStacktraceToString(Throwable throwable, Throwable.TraceInfo localTraceInfo, int removeExtraLines)
    @trusted
{
    import std.algorithm: commonPrefix, count;
    import std.range: dropBack, retro;

    // convert foreach() overloads to arrays
    string[] array(Throwable.TraceInfo info) {
        string[] result;
        foreach (line; info) result ~= line.idup;
        return result;
    }

    const string[] localBacktrace = array(localTraceInfo);
    const string[] otherBacktrace = array(throwable.info);
    // cut off shared lines of backtrace (plus some extra)
    const size_t linesToRemove = otherBacktrace.retro.commonPrefix(localBacktrace.retro).count + removeExtraLines;
    const string[] uniqueBacktrace = otherBacktrace.dropBack(linesToRemove);
    // temporarily replace the TraceInfo for toString(); yes, hacky ¯\_(ツ)_/¯
    auto originalTraceInfo = throwable.info;
    scope(exit) throwable.info = originalTraceInfo; // crucial for druntime v2.102+
    throwable.info = new class Throwable.TraceInfo {
        override int opApply(scope int delegate(ref const(char[])) dg) const {
            foreach (ref line; uniqueBacktrace)
                if (int ret = dg(line)) return ret;
            return 0;
        }
        override int opApply(scope int delegate(ref size_t, ref const(char[])) dg) const {
            foreach (ref i, ref line; uniqueBacktrace)
                if (int ret = dg(i, line)) return ret;
            return 0;
        }
        override string toString() const { assert(false); }
    };
    return throwable.toString();
}

version(OSX) {}
else {
    unittest {
        import std.conv : to;
        import std.string : splitLines, indexOf;
        import std.format : format;

        Exception localException;

        try
            throw new Exception("");
        catch (Exception exc)
            localException = exc;

        Exception exc;
        // make sure we have at least one line of backtrace of our own
        void nested()
        {
            try
                throw new Exception("");
            catch (Exception exc_)
                exc = exc_;
        }
        nested;

        const output = exc.localStacktraceToString(localException.info, 0);
        const lines = output.splitLines;

        /*
         * The text of a stacktrace can differ between compilers and also paths differ between Unix and Windows.
         * Example exception test from dmd on unix:
         *
         * object.Exception@subpackages/runner/source/unit_threaded/runner/testcase.d(368)
         * ----------------
         * subpackages/runner/source/unit_threaded/runner/testcase.d:368 void unit_threaded.runner.testcase [...]
         */
        import std.stdio : writeln;
        writeln("Output from local stack trace was " ~ to!string(lines.length) ~ " lines:\n"~output~"\n");

        assert(lines.length >= 3, "Expected 3 or more lines but got " ~ to!string(lines.length) ~ " :\n" ~ output);
        assert(lines[0].indexOf("object.Exception@") != -1, "Line 1 of stack trace should show exception type. Was: "~lines[0]);
        assert(lines[1].indexOf("------") != -1); // second line is a bunch of dashes
        //assert(lines[2].indexOf("testcase.d") != -1); // the third line differs accross compilers and not reliable for testing
    }
}
