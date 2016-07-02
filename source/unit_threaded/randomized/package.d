module unit_threaded.randomized;

public import unit_threaded.randomized.gen;
public import unit_threaded.randomized.random;
public import unit_threaded.randomized.benchmark;

unittest
{
    import core.thread : Thread;
    import core.time : seconds;

    struct Foo
    {
        void superSlowMethod(int a, Gen!(int, -10, 10) b)
            {
                Thread.sleep(1.seconds / 250000);
                doNotOptimizeAway(a);
            }
    }

    Foo a;

    auto del = delegate(int ai, Gen!(int, -10, 10) b) {
        a.superSlowMethod(ai, b);
    };

    benchmark!(del)();
}

unittest // test that the function parameter names are correct
{
    import std.string : indexOf;
    import std.experimental.logger;

    class SingleLineLogger : Logger
    {
        this()
            {
                super(LogLevel.info);
            }

        override void writeLogMsg(ref LogEntry payload) @safe
            {
                this.line = payload.msg;
            }

        string line;
    }

    auto oldLogger = stdThreadLocalLog;
    auto newLogger = new SingleLineLogger();
    stdThreadLocalLog = newLogger;
    scope (exit)
        stdThreadLocalLog = oldLogger;

    static int failingFun(int a, string b)
    {
        throw new Exception("Hello");
    }

    log();
    benchmark!failingFun();

    assert(newLogger.line.indexOf("'a'") != -1);
    assert(newLogger.line.indexOf("'b'") != -1);
}
