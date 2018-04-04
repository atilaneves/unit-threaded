module unit_threaded.ut.randomized.gen;

import unit_threaded.randomized.gen;

@safe pure unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    Gen!int gen;
    assertEqual(gen.gen(rnd), 0);
    assertEqual(gen.gen(rnd), 1);
    assertEqual(gen.gen(rnd), int.min);
    assertEqual(gen.gen(rnd), int.max);
    assertEqual(gen.gen(rnd), 1125387415); //1st non front-loaded value
}

@safe unittest {
    // not pure because of floating point flags
    import unit_threaded.asserts: assertEqual;
    import std.math: approxEqual;
    import std.conv: to;
    import std.random: Random;

    auto rnd = Random(1337);
    Gen!float gen;
    assertEqual(gen.gen(rnd), 0);
    assertEqual(gen.gen(rnd), float.epsilon);
    assertEqual(gen.gen(rnd), float.min_normal);
    assert(approxEqual(gen.gen(rnd), 6.022E23), gen.value.to!string);
    assert(approxEqual(gen.gen(rnd), 1.57791E23), gen.value.to!string);
}


@safe unittest {
    // not pure because of floating point flags
    import unit_threaded.asserts: assertEqual;
    import std.math: approxEqual;
    import std.conv: to;
    import std.random: Random;

    auto rnd = Random(1337);
    Gen!(float, 0, 5) gen;
    assertEqual(gen.gen(rnd), 0);
    assertEqual(gen.gen(rnd), float.epsilon);
    assertEqual(gen.gen(rnd), float.min_normal);
    assertEqual(gen.gen(rnd), 5);
    assert(approxEqual(gen.gen(rnd), 1.31012), gen.value.to!string);
}

unittest
{
    import std.meta : AliasSeq, aliasSeqOf;
    import std.range : iota;
    import std.array : empty;
    import std.random: Random;
    import unit_threaded.asserts;

    foreach (index, T; AliasSeq!(string, wstring, dstring)) {
        auto r = Random(1337);
        Gen!T a;
        T expected = "";
        assertEqual(a.gen(r), expected);
        expected = "a";
        assertEqual(a.gen(r), expected);
        expected = "é";
        assertEqual(a.gen(r), expected);
        assert(a.gen(r).length > 1);
    }
}

@safe unittest {
    import unit_threaded.asserts;
    import std.random: Random;

    auto rnd = Random(1337);
    GenASCIIString!() gen;
    assertEqual(gen.gen(rnd), "");
    assertEqual(gen.gen(rnd), "a");
    version(Windows)
        assertEqual(gen.gen(rnd), "yt4>%PnZwJ*Nv3L5:9I#N_ZK");
    else
        assertEqual(gen.gen(rnd), "i<pDqp7-LV;W`d)w/}VXi}TR=8CO|m");
}

@("Gen!int[] generates random arrays of int")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!(int[], 1, 10)();

    // first the front-loaded values
    assertEqual(gen.gen(rnd), []);
    version(Windows)
        assertEqual(gen.gen(rnd), [0, 1]);
    else
        assertEqual(gen.gen(rnd), [0, 1, -2147483648, 2147483647, 681542492, 913057000, 1194544295, -1962453543, 1972751015]);
}

@("Gen!ubyte[] generates random arrays of ubyte")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!(ubyte[], 1, 10)();
    assertEqual(gen.gen(rnd), []);
}


@("Gen!double[] generates random arrays of double")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!(double[], 1, 10)();

    // first the front-loaded values
    assertEqual(gen.gen(rnd), []);
    // then the pseudo-random ones
    version(Windows)
        assertEqual(gen.gen(rnd).length, 2);
    else
        assertEqual(gen.gen(rnd).length, 9);
}

@("Gen!string[] generates random arrays of string")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!(string[])();

    assertEqual(gen.gen(rnd), []);
    auto strings = gen.gen(rnd);
    assert(strings.length > 1);
    assertEqual(strings[1], "a");
}

@("Gen!string[][] generates random arrays of string")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!(string[][])();

    assertEqual(gen.gen(rnd), []);
    // takes too long
    // auto strings = gen.gen(rnd);
    // assert(strings.length > 1);
}

@("Gen!bool generates random booleans")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    auto rnd = Random(1337);
    auto gen = Gen!bool();

    assertEqual(gen.gen(rnd), true);
    assertEqual(gen.gen(rnd), true);
    assertEqual(gen.gen(rnd), false);
    assertEqual(gen.gen(rnd), false);
}

@("Gen char, wchar, dchar")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    {
        auto rnd = Random(1337);
        Gen!char gen;
        assertEqual(cast(int)gen.gen(rnd), 151);
    }
    {
        auto rnd = Random(1337);
        Gen!wchar gen;
        assertEqual(cast(int)gen.gen(rnd), 3223);
    }
    {
        auto rnd = Random(1337);
        Gen!dchar gen;
        assertEqual(cast(int)gen.gen(rnd), 3223);
    }
}

@("struct")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    struct Foo {
        int i;
        string s;
    }

    auto rnd = Random(1337);
    Gen!Foo gen;
    assertEqual(gen.gen(rnd), Foo(0, ""));
    assertEqual(gen.gen(rnd), Foo(1, "a"));
    assertEqual(gen.gen(rnd), Foo(int.min, "é"));
}

@("class")
@safe unittest {
    import unit_threaded.asserts: assertEqual;
    import std.random: Random;

    static class Foo {
        this() {}
        this(int i, string s) { this.i = i; this.s = s; }
        override string toString() @safe const pure nothrow {
            import std.conv;
            return text(`Foo(`, i, `, "`, s, `")`);
        }
        override bool opEquals(Object _rhs) @safe const pure nothrow {
            auto rhs = cast(Foo)_rhs;
            return i == rhs.i && s == rhs.s;
        }
        int i;
        string s;
    }

    auto rnd = Random(1337);
    Gen!Foo gen;
    assertEqual(gen.gen(rnd), new Foo(0, ""));
    assertEqual(gen.gen(rnd), new Foo(1, "a"));
    assertEqual(gen.gen(rnd), new Foo(int.min, "é"));
}
