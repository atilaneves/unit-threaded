module unit_threaded.property;

import std.random: Random;
import std.traits: isIntegral, isArray;


version(unittest) import unit_threaded.asserts;

Random gRandom;


static this() {
    import std.random: unpredictableSeed;
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

    import unit_threaded.randomized.random: RndValueGen;
    import unit_threaded.should: UnitTestException;
    import std.conv: text, to;
    import std.traits: ReturnType, Parameters, isSomeString;
    import std.array: join;

    static assert(is(ReturnType!F == bool),
                  text("check only accepts functions that return bool, not ", ReturnType!F.stringof));

    auto gen = RndValueGen!(Parameters!F)(&gRandom);

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

void checkCustom(alias Generator, alias Predicate)
                (int numFuncCalls = 100, in string file = __FILE__, in size_t line = __LINE__) @trusted {

    import unit_threaded.should: UnitTestException;
    import std.conv: to, text;
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
            throw new PropertyException("Error calling property function\n" ~ t.toString, file, line, t);
        }

        if(!pass) {
            throw new UnitTestException(["Property failed with input:", object.to!string], file, line);
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
    import unit_threaded.should;
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
    import unit_threaded.should;
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
    // since Gen!int[] is front-loaded, it'll fail deterministically
    assertExceptionMsg(check!((int[] a) => a.length % 2 == 1),
                       "    source/unit_threaded/property.d:123 - Property failed with input:\n" ~
                       "    source/unit_threaded/property.d:123 - []");
}


@("Explicit Gen")
@safe unittest {
    import unit_threaded.randomized.gen;
    import unit_threaded.should;

    check!((Gen!(int, 1, 1) a) => a == 1);
    check!((Gen!(int, 1, 1) a) => a == 2).shouldThrow!UnitTestException;
}

private enum canShrink(T) = __traits(compiles, shrink!((T _) => true)(T.init));

T shrink(alias F, T)(T value) {
    import std.conv: text;
    assert(!F(value), text("Property did not fail for value ", value));
    T[][] oldParams;
    return shrinkImpl!F(value, [value], oldParams);
}

private T shrinkImpl(alias F, T)(in T value, T[] candidates, T[][] oldParams = []) if(isIntegral!T) {
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

private T shrinkImpl(alias F, T)(T value, T[] candidates, T[][] oldParams = []) if(isArray!T) {
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
                       "    source/unit_threaded/property.d:123 - Property failed with input:\n" ~
                       "    source/unit_threaded/property.d:123 - 3");
}

@("string[]")
unittest {
    bool identity(string[] a) pure {
        return a == a;
    }
    check!identity;
}

unittest {
    struct Foo {
        int i;
        short s;
    }

    bool identity(Foo f) pure {
        return f == f;
    }

    check!identity;
}

@("issue 93 uint")
unittest {
    import unit_threaded.should;
    check!((uint i) => i != i).shouldThrowWithMessage("Property failed with input:\n0");
}

@("issue 93 array")
unittest {
    import unit_threaded.should;
    check!((int[] i) => i != i).shouldThrowWithMessage("Property failed with input:\n[]");
}
