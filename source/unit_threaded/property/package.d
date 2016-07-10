module unit_threaded.property;

public import unit_threaded.should;

import unit_threaded.randomized.gen;
import unit_threaded.randomized.random;
import std.random: Random, unpredictableSeed;

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

    void error(T...)(T input) {
        throw new UnitTestException(["Property failed with input:", input.to!string], file, line);
    }

    auto gen = RndValueGen!(Parameters!F)(&gRandom);
    import unit_threaded.io;
    foreach(i; 0 .. numFuncCalls) {
        gen.genValues;
        if(!F(gen.values))
            error(gen.values);
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
    import unit_threaded.asserts;

    // 2^100 is ~1.26E30, so the chances that no even length array is generated
    // is small enough to disconsider even if it were truly random
    // since Gen!int[] is front-loaded, it'll fail on the second attempt
    assertExceptionMsg(check!((int[] a) => a.length % 2 == 0),
                       "    source/unit_threaded/property/package.d:123 - Property failed with input:\n"
                       "    source/unit_threaded/property/package.d:123 - [0]");
}


@("Explicit Gen")
@system unittest {
    check!((Gen!(int, 1, 1) a) => a == 1);
    check!((Gen!(int, 1, 1) a) => a == 2).shouldThrow!UnitTestException;
}
