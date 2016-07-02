module unit_threaded.randomized.random;

import std.random : Random;

import unit_threaded.randomized.gen;

/** This type will generate a $(D Gen!T) for all passed $(D T...).
Every call to $(D genValues) will call $(D gen) of all $(D Gen) structs
present in $(D values). The member $(D values) can be passed to every
function accepting $(D T...).
*/
struct RndValueGen(T...)
{
	import std.meta : staticMap;

    /* $(D Values) is a collection of $(D Gen) types created through
    $(D ParameterToGen) of passed $(T ...).
    */
    alias Values = staticMap!(ParameterToGen, T[1 .. $]);
    /// Ditto
    Values values;

    string[] parameterNames = T[0];

    /* The constructor accepting the required random number generator.
    Params:
        rnd = The required random number generator.
    */
    this(Random* rnd)
    {
        this.rnd = rnd;
    }

    /* The random number generator used to generate new value for all
    $(D values).
    */
    Random* rnd;

    /** A call to this member function will call $(D gen) on all items in
    $(D values) passing $(D the provided) random number generator
    */
    void genValues()
    {
        foreach (ref it; this.values)
        {
            it.gen(*this.rnd);
        }
    }

    void toString(scope void delegate(const(char)[]) sink)
    {
        import std.format : formattedWrite;

        foreach (idx, ref it; values)
        {
            formattedWrite(sink, "'%s' = %s ", parameterNames[idx], it);
        }
    }
}

///
unittest
{
    auto rnd = Random(1337);
    auto generator = RndValueGen!(["i", "f"], Gen!(int, 0, 10), Gen!(float,
        0.0, 10.0))(&rnd);
    generator.genValues();

    static fun(int i, float f)
    {
        assert(i >= 0 && i <= 10);
        assert(f >= 0.0 && i <= 10.0);
    }

    fun(generator.values);
}

unittest
{
    static fun(int i, float f)
    {
        assert(i >= 0 && i <= 10);
        assert(f >= 0.0 && i <= 10.0);
    }

    auto rnd = Random(1337);
    auto generator = RndValueGen!(["i", "f"], Gen!(int, 0, 10), Gen!(float,
        0.0, 10.0))(&rnd);

    generator.genValues();
    foreach (i; 0 .. 1000)
    {
        fun(generator.values);
    }
}

/** A template that turns a $(D T) into a $(D Gen!T) unless $(D T) is
already a $(D Gen) or no $(D Gen) for given $(D T) is available.
*/
template ParameterToGen(T)
{
	import std.traits : isIntegral, isFloatingPoint, isSomeString;
    static if (isGen!T)
        alias ParameterToGen = T;
    else static if (isIntegral!T)
        alias ParameterToGen = Gen!(T, T.min, T.max);
    else static if (isFloatingPoint!T)
        alias ParameterToGen = Gen!(T, T.min_normal, T.max);
    else static if (isSomeString!T)
        alias ParameterToGen = Gen!(T, 0, 32);
    else static if (is(T : GenASCIIString!(S), S...))
        alias ParameterToGen = T;
    else
        static assert(false);
}

///
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

unittest
{
	import std.meta : AliasSeq, staticMap;

    foreach (T; AliasSeq!(byte, ubyte, ushort, short, uint, int, ulong, long,
            float, double, real, string, wstring,
            dstring))
    {
        alias TP = staticMap!(ParameterToGen, T);
        static assert(isGen!TP);
    }
}
