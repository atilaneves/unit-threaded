module unit_threaded.tests.randomized.benchmark;

import core.time : MonoTimeImpl, Duration, ClockType, dur, seconds;
import std.array : appender, array;
import std.datetime : StopWatch, DateTime, Clock;
import std.meta : staticMap;
import std.conv : to;
import std.random : Random, uniform;
import std.traits : fullyQualifiedName, isFloatingPoint, isIntegral, isNumeric,
    isSomeString, Parameters, ParameterIdentifierTuple;
import std.typetuple : TypeTuple;
import std.utf : byDchar, count;

/* This function used $(D MonoTimeImpl!(ClockType.precise).currTime) to time
how long $(D MonoTimeImpl!(ClockType.precise).currTime) takes to return
the current time.
*/
private auto medianStopWatchTime()
{
    import core.time;
    import std.algorithm : sort;

    enum numRounds = 51;
    Duration[numRounds] times;

    MonoTimeImpl!(ClockType.precise) dummy;
    for (size_t i = 0; i < numRounds; ++i)
    {
        auto sw = MonoTimeImpl!(ClockType.precise).currTime;
        dummy = MonoTimeImpl!(ClockType.precise).currTime;
        dummy = MonoTimeImpl!(ClockType.precise).currTime;
        doNotOptimizeAway(dummy);
        times[i] = MonoTimeImpl!(ClockType.precise).currTime - sw;
    }

    sort(times[]);

    return times[$ / 2].total!"hnsecs";
}

private Duration getQuantilTick(double q)(Duration[] ticks) pure @safe
{
    size_t idx = cast(size_t)(ticks.length * q);

    if (ticks.length % 2 == 1)
    {
        return ticks[idx];
    }
    else
    {
        return (ticks[idx] + ticks[idx - 1]) / 2;
    }
}

unittest
{
    static import std.conv;
    import std.algorithm.iteration : map;

    auto ticks = [1, 2, 3, 4, 5].map!(a => dur!"seconds"(a)).array;

    Duration q25 = getQuantilTick!0.25(ticks);
    assert(q25 == dur!"seconds"(2), q25.toString());

    Duration q50 = getQuantilTick!0.50(ticks);
    assert(q50 == dur!"seconds"(3), q25.toString());

    Duration q75 = getQuantilTick!0.75(ticks);
    assert(q75 == dur!"seconds"(4), q25.toString());

    q25 = getQuantilTick!0.25(ticks[0 .. 4]);
    assert(q25 == dur!"seconds"(1) + dur!"msecs"(500), q25.toString());

    q50 = getQuantilTick!0.50(ticks[0 .. 4]);
    assert(q50 == dur!"seconds"(2) + dur!"msecs"(500), q25.toString());

    q75 = getQuantilTick!0.75(ticks[0 .. 4]);
    assert(q75 == dur!"seconds"(3) + dur!"msecs"(500), q25.toString());
}

/** This $(D struct) takes care of the time taking and outputting of the
statistics.
*/
struct Benchmark
{
    import std.array : Appender;

    string filename; // where to write the benchmark result to
    string funcname; // the name of the benchmark
    size_t rounds; // the number of times the functions is supposed to be
    //executed
    string timeScale; // the unit the benchmark is measuring in
    real medianStopWatch; // the median time it takes to get the clocktime twice
    bool dontWrite; // if set, no data is written to the the file name "filename"
    // true if, RndValueGen opApply was interrupt unexpectitally
    Appender!(Duration[]) ticks; // the stopped times, there will be rounds ticks
    size_t ticksIndex = 0; // the index into ticks
    size_t curRound = 0; // the number of rounds run
    MonoTimeImpl!(ClockType.precise) startTime;
    Duration timeSpend; // overall time spend running the benchmark function

    /** The constructor for the $(D Benchmark).
    Params:
        funcname = The name of the $(D benchmark) instance. The $(D funcname)
            will be used to associate the results with the function
        filename = The $(D filename) will be used as a filename to store the
            results.
    */
    this(in string funcname, in size_t rounds, in string filename)
    {
        this.filename = filename;
        this.funcname = funcname;
        this.rounds = rounds;
        this.timeScale = "hnsecs";
        this.ticks = appender!(Duration[])();
        this.medianStopWatch = medianStopWatchTime();
    }

    /** A call to this method will start the time taking process */
    void start()
    {
        this.startTime = MonoTimeImpl!(ClockType.precise).currTime;
    }

    /** A call to this method will stop the time taking process, and
    appends the execution time to the $(D ticks) member.
    */
    void stop()
    {
        auto end = MonoTimeImpl!(ClockType.precise).currTime;
        Duration dur = end - this.startTime;
        this.timeSpend += dur;
        this.ticks.put(dur);
        ++this.curRound;
    }

    ~this()
    {
        import std.stdio : File;

        if (!this.dontWrite && this.ticks.data.length)
        {
            import std.algorithm : sort;

            auto sortedTicks = this.ticks.data;
            sortedTicks.sort();

            auto f = File(filename ~ "_bechmark.csv", "a");
            scope (exit)
                f.close();

            auto q0 = sortedTicks[0].total!("hnsecs")() /
                cast(double) this.rounds;
            auto q25 = getQuantilTick!0.25(sortedTicks).total!("hnsecs")() /
                cast(double) this.rounds;
            auto q50 = getQuantilTick!0.50(sortedTicks).total!("hnsecs")() /
                   cast(double) this.rounds;
            auto q75 = getQuantilTick!0.75(sortedTicks).total!("hnsecs")() /
                cast(double) this.rounds;
            auto q100 = sortedTicks[$ - 1].total!("hnsecs")() /
                cast(double) this.rounds;

            // funcname, the data when the benchmark was created, unit of time,
            // rounds, medianStopWatch, low, 0.25 quantil, median,
            // 0.75 quantil, high
            f.writefln(
                "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\""
                ~ ",\"%s\"",
                this.funcname, Clock.currTime.toISOExtString(),
                this.timeScale, this.curRound, this.medianStopWatch,
                q0 > this.medianStopWatch ? q0 - this.medianStopWatch : 0,
                q25 > this.medianStopWatch ? q25 - this.medianStopWatch : 0,
                q50 > this.medianStopWatch ? q50 - this.medianStopWatch : 0,
                q75 > this.medianStopWatch ? q75 - this.medianStopWatch : 0,
                q100 > this.medianStopWatch ? q100 - this.medianStopWatch : 0);
        }
    }
}
