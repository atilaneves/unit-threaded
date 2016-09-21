module unit_threaded.property;

public import unit_threaded.should;

import unit_threaded.randomized.gen;
import unit_threaded.randomized.random;
import std.random: Random, unpredictableSeed;
import std.traits: isIntegral, isArray;

version(unittest) import unit_threaded.asserts;

Random gRandom;


static this() {
    gRandom = Random(unpredictableSeed);
}


class PropertyException : Exception
{
    this(in string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
    }
}

void check(alias F)(int numFuncCalls = 100,
                    in string file = __FILE__, in size_t line = __LINE__) @trusted {
    import std.traits;
    import std.conv;
    import std.typecons;
    import std.array;

    static assert(is(ReturnType!F == bool),
                  text("check only accepts functions that return bool, not ", ReturnType!F.stringof));

    auto gen = RndValueGen!(Parameters!F)(&gRandom);

    import unit_threaded.io;
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
            throw new PropertyException("Error calling property function\n" ~ t.toString, file, line, t);
        }

        if(!pass) {
            string[] input;

            static if(Parameters!F.length == 1 && canShrink!(Parameters!F[0])) {
                input ~= gen.values[0].value.shrink!F.to!string;
                static if(isSomeString!(Parameters!F[0]))
                    input[$-1] = `"` ~ input[$-1] ~ `"`;
            } else
                foreach(j, ref valueGen; gen.values) {
                    input ~= valueGen.to!string;
                }

            throw new UnitTestException(["Property failed with input:", input.join(", ")], file, line);
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
    // gets called twice due to shrinking
    numCalls.shouldEqual(2);
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

private enum canShrink(T) = __traits(compiles, shrink!((T _) => true)(T.init));

T shrink(alias F, T)(T value) {
    import std.conv: text;
    assert(!F(value), text("Property did not fail for value ", value));
    return shrinkImpl!F(value, [value]);
}

private T shrinkImpl(alias F, T)(T value, T[] values) if(isIntegral!T) {
    import std.algorithm: canFind, minPos;
    import std.traits: isSigned;

    if(value < T.max && F(value + 1)) return value;
    if(value > T.min && F(value - 1)) return value;

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
    auto max = values.minPos!"a > b"[0]; // maxPos doesn't exist before DMD 2.071.0

    if(!F(min)) return shrinkImpl!F(min, values);
    if(!F(max)) return shrinkImpl!F(max, values);

    return values[0];
}

static assert(canShrink!int);

@("shrink int when already shrunk")
@safe pure unittest {
    assertEqual(0.shrink!(a => a != 0), 0);
}


@("shrink int when not already shrunk going up")
@safe pure unittest {
    assertEqual(0.shrink!(a => a > 3), 3);
}

@("shrink int when not already shrunk going down")
@safe pure unittest {
    assertEqual(10.shrink!(a => a < -3), -3);
}

@("shrink int.max")
@safe pure unittest {
    assertEqual(int.max.shrink!(a => a == 0), 1);
    assertEqual(int.min.shrink!(a => a == 0), -1);
    assertEqual(int.max.shrink!(a => a < 3), 3);
}

@("shrink unsigneds")
@safe pure unittest {
    import std.meta;
    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong)) {
        T value = 3;
        assertEqual(value.shrink!(a => a == 0), 1);
    }
}

private T shrinkImpl(alias F, T)(T value, T[] values) if(isArray!T) {
    if(value == []) return value;

    if(value.length == 1) {
        T empty;
        return !F(empty) ? empty : value;
    }

    auto fst = value[0 .. $ / 2];
    auto snd = value[$ / 2 .. $];
    if(!F(fst)) return shrinkImpl!F(fst, values);
    if(!F(snd)) return shrinkImpl!F(snd, values);

    if(F(value[0 .. $ - 1])) return value[0 .. $ - 1];
    if(F(value[1 .. $])) return value[1 .. $];

    if(!F(value[0 .. $ - 1])) return shrinkImpl!F(value[0 .. $ - 1], values);
    if(!F(value[1 .. $])) return shrinkImpl!F(value[1 .. $], values);
    return values[0];
}

@("shrink empty int array")
@safe pure unittest {
    int[] value;
    assertEqual(value.shrink!(a => a != []), value);
}

@("shrink int array")
@safe pure unittest {
    assertEqual([1, 2, 3].shrink!(a => a == []), [1]);
}

@("shrink string")
@safe pure unittest {
    import std.algorithm: canFind;
    assertEqual("abcdef".shrink!(a => !a.canFind("e")), "e");
}

@("shrink one item with check")
unittest {
    assertEqual("ǭĶƶØľĶĄÔ0".shrink!((s) => s.length < 3 || s[2] == 'e'), "ǭ");
}

@("shrink one item with check")
unittest {
    assertExceptionMsg(check!((int i) => i < 3),
                       "    source/unit_threaded/property/package.d:123 - Property failed with input:\n"
                       "    source/unit_threaded/property/package.d:123 - 3");
}
