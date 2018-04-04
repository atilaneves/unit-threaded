/**
   Property-based testing.
 */
module unit_threaded.property;


template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}


///
class PropertyException : Exception
{
    this(in string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
    }
}

/**
   Check that bool-returning F is true with randomly generated values.
 */
void check(alias F, int numFuncCalls = 100)
          (in uint seed = from!"std.random".unpredictableSeed,
           in string file = __FILE__,
           in size_t line = __LINE__)
    @trusted
{

    import unit_threaded.randomized.random: RndValueGen;
    import unit_threaded.should: UnitTestException;
    import std.conv: text;
    import std.traits: ReturnType, Parameters, isSomeString;
    import std.array: join;
    import std.typecons: Flag, Yes, No;
    import std.random: Random;

    static assert(is(ReturnType!F == bool),
                  text("check only accepts functions that return bool, not ", ReturnType!F.stringof));

    auto random = Random(seed);
    auto gen = RndValueGen!(Parameters!F)(&random);

    auto input(Flag!"shrink" shrink = Yes.shrink) {
        string[] ret;
        static if(Parameters!F.length == 1 && canShrink!(Parameters!F[0])) {
            auto val = gen.values[0].value;
            auto shrunk = shrink ? val.shrink!F : val;
            ret ~= shrunk.text;
            static if(isSomeString!(Parameters!F[0]))
                ret[$-1] = `"` ~ ret[$-1] ~ `"`;
        } else
            foreach(ref valueGen; gen.values) {
                ret ~= valueGen.text;
            }
        return ret.join(", ");
    }

    foreach(i; 0 .. numFuncCalls) {
        bool pass;

        try {
            gen.genValues;
        } catch(Throwable t) {
            throw new PropertyException("Error generating values\n" ~ t.toString, file, line, t);
        }

        try {
            pass = F(gen.values);
        } catch(Throwable t) {
            // trying to shrink when an exeption is thrown is too much of a bother code-wise
            throw new UnitTestException(
                text("Property threw. Seed: ", seed, ". Input: ", input(No.shrink), ". Message: ", t.msg),
                file,
                line,
                t,
            );
        }

        if(!pass) {
            throw new UnitTestException(text("Property failed. Seed: ", seed, ". Input: ", input), file, line);
        }
    }
}

/**
   For values that unit-threaded doesn't know how to generate, test that the Predicate
   holds, using Generator to come up with new values.
 */
void checkCustom(alias Generator, alias Predicate)
                (int numFuncCalls = 100, in string file = __FILE__, in size_t line = __LINE__) @trusted {

    import unit_threaded.should: UnitTestException;
    import std.conv: text;
    import std.traits: ReturnType;

    static assert(is(ReturnType!Predicate == bool),
                  text("check only accepts functions that return bool, not ", ReturnType!F.stringof));

    alias Type = ReturnType!Generator;

    foreach(i; 0 .. numFuncCalls) {

        Type object;

        try {
            object = Generator();
        } catch(Throwable t) {
            throw new PropertyException("Error generating value\n" ~ t.toString, file, line, t);
        }

        bool pass;

        try {
            pass = Predicate(object);
        } catch(Throwable t) {
            throw new UnitTestException(
                text("Property threw. Input: ", object, ". Message: ", t.msg),
                file,
                line,
                t,
            );
        }

        if(!pass) {
            throw new UnitTestException("Property failed with input:" ~ object.text, file, line);
        }
    }
}


private auto shrinkOne(alias F, int index, T)(T values) {
    import std.stdio;
    import std.traits;
    auto orig = values[index];
    return shrink!((a) {
        values[index] = a;
        return F(values.expand);
    })(orig);

}

///
@("Verify identity property for int[] succeeds")
@safe unittest {

    int numCalls;
    bool identity(int[] a) pure {
        ++numCalls;
        return a == a;
    }

    check!identity;
    assert(numCalls == 100);

    numCalls = 0;
    check!(identity, 10);
    assert(numCalls == 10);
}

///
@("Explicit Gen")
@safe unittest {
    import unit_threaded.randomized.gen;
    import unit_threaded.should: UnitTestException;
    import std.exception: assertThrown;

    check!((Gen!(int, 1, 1) a) => a == 1);
    assertThrown!UnitTestException(check!((Gen!(int, 1, 1) a) => a == 2));
}

private enum canShrink(T) = __traits(compiles, shrink!((T _) => true)(T.init));

T shrink(alias F, T)(T value) {
    import std.conv: text;

    assert(!F(value), text("Property did not fail for value ", value));

    T[][] oldParams;
    return shrinkImpl!F(value, [value], oldParams);
}

private T shrinkImpl(alias F, T)(in T value, T[] candidates, T[][] oldParams = [])
    if(from!"std.traits".isIntegral!T)
{
    import std.algorithm: canFind, minPos;
    import std.traits: isSigned;

    auto params = value ~ candidates;
    if(oldParams.canFind(params)) return value;
    oldParams ~= params;

    // if it suddenly starts passing we've found our boundary value
    if(value < T.max && F(value + 1)) return value;
    if(value > T.min && F(value - 1)) return value;

    bool stillFails(T attempt) {
        if(!F(attempt) && !candidates.canFind(attempt)) {
            candidates ~= attempt;
            return true;
        }

        return false;
    }

    T[] attempts;
    if(value != 0) {
        static if(isSigned!T) attempts ~= -value;
        attempts ~= value / 2;
    }
    if(value < T.max / 2) attempts ~= cast(T)(value * 2);
    if(value < T.max) attempts ~= cast(T)(value + 1);
    if(value > T.min) attempts ~= cast(T)(value - 1);

    foreach(attempt; attempts)
        if(stillFails(attempt))
            return shrinkImpl!F(attempt, candidates, oldParams);

    const min = candidates.minPos[0];
    const max = candidates.minPos!"a > b"[0]; // maxPos doesn't exist before DMD 2.071.0

    if(!F(min)) return shrinkImpl!F(min, candidates, oldParams);
    if(!F(max)) return shrinkImpl!F(max, candidates, oldParams);

    return candidates[0];
}

static assert(canShrink!int);


private T shrinkImpl(alias F, T)(T value, T[] candidates, T[][] oldParams = [])
    if(from!"std.traits".isArray!T)
{
    if(value == []) return value;

    if(value.length == 1) {
        T empty;
        return !F(empty) ? empty : value;
    }

    auto fst = value[0 .. $ / 2];
    auto snd = value[$ / 2 .. $];
    if(!F(fst)) return shrinkImpl!F(fst, candidates);
    if(!F(snd)) return shrinkImpl!F(snd, candidates);

    if(F(value[0 .. $ - 1])) return value[0 .. $ - 1];
    if(F(value[1 .. $])) return value[1 .. $];

    if(!F(value[0 .. $ - 1])) return shrinkImpl!F(value[0 .. $ - 1], candidates);
    if(!F(value[1 .. $])) return shrinkImpl!F(value[1 .. $], candidates);
    return candidates[0];
}
