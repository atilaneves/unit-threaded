module unit_threaded.randomized.gen;

import std.traits : isSomeString, isNumeric, isFloatingPoint, isIntegral;
import std.random : uniform, Random;
import std.range: isInputRange, ElementType;
import std.algorithm: filter;
import std.array: array;

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

private template minimum(T) {
    import std.traits: isIntegral, isFloatingPoint;
    static if(isIntegral!T)
        enum minimum = T.min;
    else static if (isFloatingPoint!T)
        enum mininum = T.min_normal;
    else
        enum minimum = T.init;
}

private template maximum(T) {
    static if(isNumeric!T)
        enum maximum = T.max;
    else
        enum maximum = T.init;
}

/** A $(D Gen) type that generates numeric values between the values of the
template parameter $(D low) and $(D high).
*/
mixin template GenNumeric(T, T low, T high) {

    static assert(is(typeof(() {
        T[] res = frontLoaded();
    })), "GenNumeric needs a function frontLoaded returning " ~ T.stringof ~ "[]");

    alias Value = T;

    T value;

    T gen(ref Random gen)
    {
        static assert(low <= high);

        this.value = _index < frontLoaded.length
            ? frontLoaded[_index++]
            : uniform!("[]")(low, high, gen);

        return this.value;
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


    private int _index;
}

/** A $(D Gen) type that generates numeric values between the values of the
template parameter $(D low) and $(D high).
*/
struct Gen(T, T low = minimum!T, T high = maximum!T) if (isIntegral!T)
{
    private T[] frontLoaded() @safe pure nothrow {
        T[] values = [0, 1, T.min, T.max];
        return values.filter!(a => a >= low && a <= high).array;
    }

    mixin GenNumeric!(T, low, high);
}

struct Gen(T, T low = 0, T high = 6.022E23) if(isFloatingPoint!T) {
     T[] frontLoaded() @safe pure nothrow {
         T[] values = [0, T.epsilon, T.min_normal, high];
         return values.filter!(a => a >= low && a <= high).array;
    }

    mixin GenNumeric!(T, low, high);
}

@safe pure unittest {
    import unit_threaded.asserts: assertEqual;

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

    auto rnd = Random(1337);
    Gen!(float, 0, 5) gen;
    assertEqual(gen.gen(rnd), 0);
    assertEqual(gen.gen(rnd), float.epsilon);
    assertEqual(gen.gen(rnd), float.min_normal);
    assertEqual(gen.gen(rnd), 5);
    assert(approxEqual(gen.gen(rnd), 1.31012), gen.value.to!string);
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

    T gen(ref Random gen)
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
        return this.value;
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
    import std.meta : AliasSeq, aliasSeqOf; //TODO uncomment with next release
    import std.range : iota;
    import std.array : empty;

    auto r = Random(1337);
    foreach (T; AliasSeq!(string, wstring, dstring))
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

    string gen(ref Random gen)
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
        return this.value;
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

struct Gen(T, size_t low = 1, size_t high = 1024) if(isInputRange!T && isNumeric!(ElementType!T)) {

    import std.traits: Unqual, isIntegral, isFloatingPoint;
    alias E = Unqual!(ElementType!T);

    T value;

    T gen(ref Random rnd) {
        value = _index < frontLoaded.length
            ? frontLoaded[_index++]
            : genArray(rnd);
        return value;
    }

    alias value this;

private:

    size_t _index;
     //these values are always generated
    T[] frontLoaded() @safe pure nothrow {
        return [[], [0], [1]];
    }

    T genArray(ref Random rnd) {
        import std.array: appender;
        immutable length = uniform(low, high, rnd);
        auto app = appender!T;
        app.reserve(length);
        foreach(i; 0 .. length) {
            static if(isIntegral!E)
                app.put(uniform(E.min, E.max, rnd));
            else static if(isFloatingPoint!E)
                app.put(uniform(-1e12, 1e12, rnd));
            else
                static assert("Cannot generage elements of type ", E.stringof);
        }

        return app.data;
    }
}

static assert(isGen!(Gen!(int[])));


@("Gen!int[] generates random arrays of int")
@safe pure unittest {
    import unit_threaded.asserts: assertEqual;

    auto rnd = Random(1337);
    auto gen = Gen!(int[], 1, 10)();

    // first the front-loaded values
    assertEqual(gen.gen(rnd), []);
    assertEqual(gen.gen(rnd), [0]);
    assertEqual(gen.gen(rnd), [1]);
    // then the first pseudo-random one
    assertEqual(gen.gen(rnd),
                [-1465941156, -1234426648, -952939353, 185030105,
                 -174732633, -2001577638, -768796814, -1136496558, 78996564]);
}

@("Gen!double[] generates random arrays of double")
@safe unittest {
    import unit_threaded.asserts: assertEqual;

    auto rnd = Random(1337);
    auto gen = Gen!(double[], 1, 10)();

    // first the front-loaded values
    assertEqual(gen.gen(rnd), []);
    assertEqual(gen.gen(rnd), [0]);
    assertEqual(gen.gen(rnd), [1]);
    assertEqual(gen.gen(rnd).length, 9);
}
