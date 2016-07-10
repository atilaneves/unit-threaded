module unit_threaded.randomized.benchmark;

import core.time : MonoTimeImpl, Duration, ClockType, dur, seconds;
import std.array : appender, array;
import std.datetime : Clock;
import std.traits : fullyQualifiedName, Parameters, ParameterIdentifierTuple;

import unit_threaded;
import unit_threaded.randomized.gen;

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

// @Name("Quantil calculations")
// unittest
// {
//     static import std.conv;
//     import std.algorithm.iteration : map;

//     auto ticks = [1, 2, 3, 4, 5].map!(a => dur!"seconds"(a)).array;

//     Duration q25 = getQuantilTick!0.25(ticks);
//     assert(q25 == dur!"seconds"(2), q25.toString());

//     Duration q50 = getQuantilTick!0.50(ticks);
//     assert(q50 == dur!"seconds"(3), q25.toString());

//     Duration q75 = getQuantilTick!0.75(ticks);
//     assert(q75 == dur!"seconds"(4), q25.toString());

//     q25 = getQuantilTick!0.25(ticks[0 .. 4]);
//     assert(q25 == dur!"seconds"(1) + dur!"msecs"(500), q25.toString());

//     q50 = getQuantilTick!0.50(ticks[0 .. 4]);
//     assert(q50 == dur!"seconds"(2) + dur!"msecs"(500), q25.toString());

//     q75 = getQuantilTick!0.75(ticks[0 .. 4]);
//     assert(q75 == dur!"seconds"(3) + dur!"msecs"(500), q25.toString());
// }

/** The options  controlling the behaviour of benchmark. */
struct BenchmarkOptions
{
    string funcname; // the name of the function to benchmark
    string filename; // the name of the file the results will be appended to
    Duration duration = 1.seconds; // the time after which the function to
                                   // benchmark is not executed anymore
    size_t maxRounds = 10000; // the maximum number of times the function
                              // to benchmark is called
    int seed = 1337; // the seed to the random number generator

    this(string funcname)
    {
        this.funcname = funcname;
    }
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

void doNotOptimizeAway(T...)(ref T t)
{
    foreach (ref it; t)
    {
        doNotOptimizeAwayImpl(&it);
    }
}

private void doNotOptimizeAwayImpl(void* p) {
        import core.thread : getpid;
        import std.stdio : writeln;
        if(getpid() == 1) {
                writeln(*cast(char*)p);
        }
}

// unittest
// {
//     static void funToBenchmark(int a, float b, Gen!(int, -5, 5) c, string d,
//         GenASCIIString!(1, 10) e)
//     {
//         import core.thread;

//         Thread.sleep(1.seconds / 100000);
//         doNotOptimizeAway(a, b, c, d, e);
//     }

//     benchmark!funToBenchmark();
//     benchmark!funToBenchmark("Another Name");
//     benchmark!funToBenchmark("Another Name", 2.seconds);
//     benchmark!funToBenchmark(2.seconds);
// }

/** This function runs the passed callable $(D T) for the duration of
$(D maxRuntime). It will count how often $(D T) is run in the duration and
how long each run took to complete.

Unless compiled in release mode, statistics will be printed to $(D stderr).
If compiled in release mode the statistics are appended to a file called
$(D name).

Params:
    opts = A $(D BenchmarkOptions) instance that encompasses all possible
        parameters of benchmark.
    name = The name of the benchmark. The name is also used as filename to
        save the benchmark results.
    maxRuntime = The maximum time the benchmark is executed. The last run will
        not be interrupted.
    rndSeed = The seed to the random number generator used to populate the
        parameter passed to the function to benchmark.
    rounds = The maximum number of times the callable $(D T) is called.
*/
void benchmark(alias T)(const ref BenchmarkOptions opts)
{
        import std.random : Random;
        import unit_threaded.randomized.random;

    auto bench = Benchmark(opts.funcname, opts.maxRounds, opts.filename);
    auto rnd = Random(opts.seed);
    enum string[] parameterNames = [ParameterIdentifierTuple!T];
    auto valueGenerator = RndValueGen!(parameterNames, Parameters!T)(&rnd);

    while (bench.timeSpend <= opts.duration && bench.curRound < opts.maxRounds)
    {
        valueGenerator.genValues();

        bench.start();
        try
        {
            T(valueGenerator.values);
        }
        catch (Throwable t)
        {
            import std.experimental.logger : logf;

            logf("unittest with name %s failed when parameter %s where passed",
                opts.funcname, valueGenerator);
            break;
        }
        finally
        {
            bench.stop();
            ++bench.curRound;
        }
    }
}

/// Ditto
void benchmark(alias T)(string funcname = "", string filename = __FILE__)
{
    import std.string : empty;

    auto opt = BenchmarkOptions(
        funcname.empty ? fullyQualifiedName!T : funcname
    );
    opt.filename = filename;
    benchmark!(T)(opt);
}

/// Ditto
void benchmark(alias T)(Duration maxRuntime, string filename = __FILE__)
{
    auto opt = BenchmarkOptions(fullyQualifiedName!T);
    opt.filename = filename;
    opt.duration = maxRuntime;
    benchmark!(T)(opt);
}

/// Ditto
/*void benchmark(alias T)(string name, string filename = __FILE__)
{
    auto opt = BenchmarkOptions(name);
    opt.filename = filename;
    benchmark!(T)(opt);
}*/

/// Ditto
void benchmark(alias T)(string name, Duration maxRuntime,
    string filename = __FILE__)
{
    auto opt = BenchmarkOptions(name);
    opt.filename = filename;
    opt.duration = maxRuntime;
    benchmark!(T)(opt);
}
