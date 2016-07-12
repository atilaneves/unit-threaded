module unit_threaded.property;

public import unit_threaded.should;

import unit_threaded.randomized.gen;
import unit_threaded.randomized.random;
import std.random: Random, unpredictableSeed;
import std.traits: isIntegral;

version(unittest) import unit_threaded.asserts;

Random gRandom;


static this() {
    gRandom = Random(unpredictableSeed);
}

void check(alias F)(int numFuncCalls = 100,
                    in string file = __FILE__, in size_t line = __LINE__) {
    import std.traits;
    import std.conv;

    static assert(is(ReturnType!F == bool),
                  text("check only accepts functions that return bool, not ", ReturnType!F.stringof));

    auto gen = RndValueGen!(Parameters!F)(&gRandom);

    import unit_threaded.io;
    foreach(i; 0 .. numFuncCalls) {
        gen.genValues;
        if(!F(gen.values))
            throw new UnitTestException(["Property failed with input:", gen.values.to!string], file, line);
    }
}

@("Verify identity property for int[] succeeds")
@safe unittest {
    int numCalls;
    bool identity(int[] a) pure {
        ++numCalls;
        return a == a;
    }

    check!identity;
    numCalls.shouldEqual(100);

    numCalls = 0;
    check!identity(10);
    numCalls.shouldEqual(10);
}

@("Verify anti-identity property for int[] fails")
@safe unittest {
    int numCalls;
    bool antiIdentity(int[] a) {
        ++numCalls;
        return a != a;
    }

    check!antiIdentity.shouldThrow!UnitTestException;
    numCalls.shouldEqual(1); // always fails so only gets called once
}

@("Verify property that sometimes succeeds")
@safe unittest {
    // 2^100 is ~1.26E30, so the chances that no even length array is generated
    // is small enough to disconsider even if it were truly random
    // since Gen!int[] is front-loaded, it'll fail on the second attempt
    assertExceptionMsg(check!((int[] a) => a.length % 2 == 0),
                       "    source/unit_threaded/property/package.d:123 - Property failed with input:\n"
                       "    source/unit_threaded/property/package.d:123 - [0]");
}


@("Explicit Gen")
@safe unittest {
    check!((Gen!(int, 1, 1) a) => a == 1);
    check!((Gen!(int, 1, 1) a) => a == 2).shouldThrow!UnitTestException;
}


T shrink(alias F, T)(T value) {
    return shrinkImpl!F(value, [value]);
}

T shrinkImpl(alias F, T)(T value, T[] values) if(isIntegral!T) {
    import std.conv: text;
    import std.algorithm: canFind, minPos, maxPos;
    import std.traits: isSigned;

    assert(!F(value), text("Property did not fail for value ", value));

    // import std.stdio;
    // writeln("value: ", value, ", values: ", values);

    if(F(value + 1)) return value;
    if(F(value - 1)) return value;

    bool try_(T attempt) {
        if(!F(attempt) && !values.canFind(attempt)) {
            values ~= attempt;
            return true;
        }

        return false;
    }

    T[] attempts;
    static if(isSigned!T) attempts ~= -value;
    attempts ~= value / 2;
    if(value < T.max / 2) attempts ~= cast(T)(value * 2);
    if(value < T.max) attempts ~= cast(T)(value + 1);
    if(value > T.min) attempts ~= cast(T)(value - 1);

    foreach(attempt; attempts)
        if(try_(attempt))
            return shrinkImpl!F(attempt, values);

    auto min = values.minPos[0];
    auto max = values.maxPos[0];

    if(!F(min)) return shrinkImpl!F(min, values);
    if(!F(max)) return shrinkImpl!F(max, values);

    return values[0];
}



@("shrink int when already shrunk")
@safe unittest {
    assertEqual(0.shrink!(a => a != 0), 0);
}


@("shrink int when not already shrunk going up")
@safe unittest {
    assertEqual(0.shrink!(a => a > 3), 3);
}

@("shrink int when not already shrunk going down")
@safe unittest {
    assertEqual(10.shrink!(a => a < -3), -3);
}

@("shrink int.max")
@safe unittest {
    assertEqual(int.max.shrink!(a => a == 0), 1);
    assertEqual(int.min.shrink!(a => a == 0), -1);
}

@("shrink unsigneds")
@safe unittest {
    import std.meta;
    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong)) {
        T value = 3;
        assertEqual(value.shrink!(a => a == 0), 1);
    }
}
