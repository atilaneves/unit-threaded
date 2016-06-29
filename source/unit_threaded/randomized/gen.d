module unit_threaded.randomized.gen;

import std.traits : isSomeString, isNumeric, isFloatingPoint;
import std.random : uniform, Random;

import unit_threaded;

/* Return $(D true) if the passed $(D T) is a $(D Gen) struct.

A $(D Gen!T) is something that implicitly converts to $(D T), has a method
called $(D gen) that is accepting a $(D ref Random).

This module already brings Gens for numeric types, strings and ascii strings.

If a function needs to be benchmarked that has a parameter of custom type a
custom $(D Gen) is required.
*/
template isGen(T)
{
    static if (is(T : Gen!(S), S...))
        enum isGen = true;
    else
        enum isGen = false;
}

///
@UnitTest
unittest
{
    static assert(!isGen!int);
    static assert(isGen!(Gen!(int, 0, 10)));
}

/** A $(D Gen) type that generates numeric values between the values of the
template parameter $(D low) and $(D high).
*/
struct Gen(T, T low, T high) if (isNumeric!T)
{
    alias Value = T;

    T value;

    void gen(ref Random gen)
    {
        static assert(low <= high);
        this.value = uniform!("[]")(low, high, gen);
    }

    ref T opCall()
    {
        return this.value;
    }

    void toString(scope void delegate(const(char)[]) sink)
    {
        import std.format : formattedWrite;

        static if (isFloatingPoint!T)
        {
            static if (low == T.min_normal && high == T.max)
            {
                formattedWrite(sink, "'%s'", this.value);
            }
        }
        else static if (low == T.min && high == T.max)
        {
            formattedWrite(sink, "'%s'", this.value);
        }
        else
        {
            formattedWrite(sink, "'%s' low = '%s' high = '%s'", this.value,
                low, high);
        }
    }

    alias opCall this;
}

/** A $(D Gen) type that generates unicode strings with a number of
charatacters that is between template parameter $(D low) and $(D high).
*/
struct Gen(T, size_t low, size_t high) if (isSomeString!T)
{
    static T charSet;
    static immutable size_t numCharsInCharSet;

    T value;

    static this()
    {
        import std.array : array;
        import std.uni : unicode;
        import std.format : format;
        import std.range : chain, iota;
        import std.algorithm : map, joiner;
		import std.conv : to;
		import std.utf : count;

        Gen!(T, low, high).charSet = to!T(chain(iota(0x21,
            0x7E).map!(a => to!T(cast(dchar) a)), iota(0xA1,
            0x1EF).map!(a => to!T(cast(dchar) a))).joiner.array);

        Gen!(T, low, high).numCharsInCharSet = count(charSet);
    }

    void gen(ref Random gen)
    {
        static assert(low <= high);
        import std.range : drop;
        import std.array : appender, front;
        import std.utf : byDchar;

        auto app = appender!T();
        app.reserve(high);
        size_t numElems = uniform!("[]")(low, high, gen);

        for (size_t i = 0; i < numElems; ++i)
        {
            size_t toSelect = uniform!("[)")(0, numCharsInCharSet, gen);
            app.put(charSet.byDchar().drop(toSelect).front);
        }

        this.value = app.data;
    }

    ref T opCall()
    {
        return this.value;
    }

    void toString(scope void delegate(const(char)[]) sink)
    {
        import std.format : formattedWrite;

        static if (low == 0 && high == 32)
        {
            formattedWrite(sink, "'%s'", this.value);
        }
        else
        {
            formattedWrite(sink, "'%s' low = '%s' high = '%s'", this.value,
                low, high);
        }
    }

    alias opCall this;
}

unittest
{
    import std.typetuple : TypeTuple;

    import std.meta : aliasSeqOf; //TODO uncomment with next release
    import std.range : iota;
    import std.array : empty;

    auto r = Random(1337);
    foreach (T; TypeTuple!(string, wstring, dstring))
    {
        foreach (L; aliasSeqOf!(iota(0, 2)))
        {
            foreach (H; aliasSeqOf!(iota(L, 2)))
            {
                Gen!(T, L, H) a;
                a.gen(r);
                if (L)
                {
                    assert(!a.value.empty);
                }
            }
        }
    }
}

/// DITTO This random $(D string)s only consisting of ASCII character
struct GenASCIIString(size_t low, size_t high)
{
    static string charSet;
    static immutable size_t numCharsInCharSet;

    string value;

    static this()
    {
        import std.array : array;
        import std.uni : unicode;
        import std.format : format;
        import std.range : chain, iota;
        import std.algorithm : map, joiner;
		import std.conv : to;
		import std.utf : byDchar, count;

        GenASCIIString!(low, high).charSet = to!string(chain(iota(0x21,
            0x7E).map!(a => to!char(cast(dchar) a)).array));

        GenASCIIString!(low, high).numCharsInCharSet = count(charSet);
    }

    void gen(ref Random gen)
    {
		import std.array : appender;
        auto app = appender!string();
        app.reserve(high);
        size_t numElems = uniform!("[]")(low, high, gen);

        for (size_t i = 0; i < numElems; ++i)
        {
            size_t toSelect = uniform!("[)")(0, numCharsInCharSet, gen);
            app.put(charSet[toSelect]);
        }

        this.value = app.data;
    }

    ref string opCall()
    {
        return this.value;
    }

    void toString(scope void delegate(const(char)[]) sink)
    {
        import std.format : formattedWrite;

        static if (low == 0 && high == 32)
        {
            formattedWrite(sink, "'%s'", this.value);
        }
        else
        {
            formattedWrite(sink, "'%s' low = '%s' high = '%s'", this.value,
                low, high);
        }
    }

    alias opCall this;
}

unittest
{
    import std.utf : validate;
    import std.array : empty;
    import std.exception : assertNotThrown;

    auto rnd = Random(1337);

    GenASCIIString!(5, 5) gen;
    gen.gen(rnd);
    auto str = gen();
    assert(!str.empty);
    assertNotThrown(validate(str));
}

struct Gen(T, size_t high = 1024, size_t low = 1) if(is(T: int[])) {

    import std.range: ElementType;
    alias E = ElementType!T;

    T gen(ref Random rnd) @safe pure {
        return _index < frontLoaded.length
            ? frontLoaded[_index++]
            : genArray(rnd);
    }

private:

    size_t _index;
     //these values are always generated
    T[] frontLoaded() @safe pure nothrow {
        return [[], [0], [1]];
    }

    T genArray(ref Random rnd) @safe pure {
        import std.array: appender;
        immutable length = uniform(low, high, rnd);
        auto app = appender!T;
        app.reserve(length);
        foreach(i; 0 .. length) {
            app.put(uniform(E.min, E.max, rnd));
        }

        return app.data;
    }
}

static assert(isGen!(Gen!(int[])));


@("Gen!int[] generates random arrays of int")
@safe pure unittest {
    import unit_threaded.asserts: assertEqual;

    auto rnd = Random(1337);
    auto gen = Gen!(int[], 10)();

    // first the front-loaded values
    assertEqual(gen.gen(rnd), []);
    assertEqual(gen.gen(rnd), [0]);
    assertEqual(gen.gen(rnd), [1]);
    // then the first pseudo-random one
    assertEqual(gen.gen(rnd),
                [-1465941156, -1234426648, -952939353, 185030105,
                 -174732633, -2001577638, -768796814, -1136496558, 78996564]);
}
