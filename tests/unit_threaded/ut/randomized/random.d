module unit_threaded.ut.randomized.random;

import unit_threaded.randomized.random;

unittest
{
    import unit_threaded.randomized.gen: Gen;
    import std.random: Random;

    auto rnd = Random(1337);
    auto generator = (&rnd).RndValueGen!(["i", "f"],
                                         Gen!(int, 0, 10),
                                         Gen!(float, 0.0, 10.0));
    generator.genValues();

    static fun(int i, float f)
    {
        import std.conv: to;
        assert(i >= 0 && i <= 10, i.to!string);
        assert(f >= 0.0 && f <= 10.0, f.to!string);
    }

    fun(generator.values);
}

@("RndValueGen can be used without parameter names")
unittest
{
    import unit_threaded.randomized.gen: Gen;
    import std.random: Random;

    auto rnd = Random(1337);
    auto generator = rnd.RndValueGen!(Gen!(int, 0, 10),
                                      Gen!(float, 0.0, 10.0));
    generator.genValues();

    static fun(int i, float f)
    {
        import std.conv: to;
        assert(i >= 0 && i <= 10, i.to!string);
        assert(f >= 0.0 && f <= 10.0, f.to!string);
    }

    fun(generator.values);
}


unittest
{
    import unit_threaded.randomized.gen: Gen;
    import std.random: Random;

    static fun(int i, float f)
    {
        assert(i >= 0 && i <= 10);
        assert(f >= 0.0 && i <= 10.0);
    }

    auto rnd = Random(1337);
    auto generator = (&rnd).RndValueGen!(["i", "f"],
                                         Gen!(int, 0, 10),
                                         Gen!(float, 0.0, 10.0));

    generator.genValues();
    foreach (i; 0 .. 1000)
    {
        fun(generator.values);
    }
}

@("RndValueGen with int[]")
unittest {
    import unit_threaded.randomized.gen: Gen;
    import std.random: Random;

    void fun(int[] i) { }
    auto rnd = Random(1337);
    auto gen = rnd.RndValueGen!(Gen!(int[]));
    gen.genValues;
    fun(gen.values);
}

unittest
{
    alias GenInt = ParameterToGen!int;

    static fun(int i)
    {
        assert(i == 1337);
    }

    GenInt a;
    a.value = 1337;
    fun(a);
}

@("RndValueGen with user defined struct")
unittest {
    import unit_threaded.randomized.gen: Gen;
    import std.random: Random;

    struct Foo {
        int i;
        short s;
    }

    auto rnd = Random(1337);
    auto gen = rnd.RndValueGen!(Gen!Foo);

    foreach(_; 0 .. 5) // get rid of front-loaded uninteresting values
        gen.genValues;

    void fun(Foo foo) {
        import std.conv: text;
        assert(foo == Foo(1125387415, -8003), text(foo));
    }

    fun(gen.values);
}


unittest
{
    import unit_threaded.randomized.gen: isGen;
    import std.random: Random;
    import std.meta : AliasSeq, staticMap;

    struct Foo {
        int i;
        double d;
    }

    foreach (T; AliasSeq!(byte, ubyte, ushort, short, uint, int, ulong, long,
                          float, double, real,
                          string, wstring, dstring, Foo))
    {
        alias TP = staticMap!(ParameterToGen, T);
        static assert(isGen!TP);
    }
}
