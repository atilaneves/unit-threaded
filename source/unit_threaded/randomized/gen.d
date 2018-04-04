module unit_threaded.randomized.gen;

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}


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
unittest
{
    static assert(!isGen!int);
    static assert(isGen!(Gen!(int, 0, 10)));
}

private template minimum(T) {
    import std.traits: isIntegral, isFloatingPoint, isSomeChar;
    static if(isIntegral!T || isSomeChar!T)
        enum minimum = T.min;
    else static if (isFloatingPoint!T)
        enum mininum = T.min_normal;
    else
        enum minimum = T.init;
}

private template maximum(T) {
    import std.traits: isNumeric;
    static if(isNumeric!T)
        enum maximum = T.max;
    else
        enum maximum = T.init;
}

/** A $(D Gen) type that generates numeric values between the values of the
template parameter $(D low) and $(D high).
*/
mixin template GenNumeric(T, T low, T high) {

    import std.random: Random;

    static assert(is(typeof(() {
        T[] res = frontLoaded();
    })), "GenNumeric needs a function frontLoaded returning " ~ T.stringof ~ "[]");

    alias Value = T;

    T value;

    T gen(ref Random gen)
    {
        import std.random: uniform;

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

    void toString(scope void delegate(const(char)[]) sink) @trusted
    {
        import std.format : formattedWrite;
        import std.traits: isFloatingPoint;

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
struct Gen(T, T low = minimum!T, T high = maximum!T) if (from!"std.traits".isIntegral!T)
{
    private static T[] frontLoaded() @safe pure nothrow {
        import std.algorithm: filter;
        import std.array: array;
        T[] values = [0, 1, T.min, T.max];
        return values.filter!(a => a >= low && a <= high).array;
    }

    mixin GenNumeric!(T, low, high);
}

struct Gen(T, T low = 0, T high = 6.022E23) if(from!"std.traits".isFloatingPoint!T) {
     private static T[] frontLoaded() @safe pure nothrow {
        import std.algorithm: filter;
        import std.array: array;
         T[] values = [0, T.epsilon, T.min_normal, high];
         return values.filter!(a => a >= low && a <= high).array;
    }

    mixin GenNumeric!(T, low, high);
}


/** A $(D Gen) type that generates ASCII strings with a number of
characters that is between template parameter $(D low) and $(D high).

If $(D low) and $(D high) are very close together, this might return
values that are too short. They should differ by at least three for
char strings, one for wstrings, and zero for dstrings.
*/
struct Gen(T, size_t low = 0, size_t high = 32) if (from!"std.traits".isSomeString!T)
{
    static const dchar[] charset;
    import std.random: Random, uniform;

    static immutable size_t numCharsInCharSet;
    alias Value = T;

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

        charset = chain(
                // \t and \n
                iota(0x09, 0x0B),
                // \r
                iota(0x0D, 0x0E),
                // ' ' through '~'; next is DEL
                iota(0x20, 0x7F),
                // Vulgar fractions, punctuation, letters with accents, Greek
                iota(0xA1, 0x377),
                // More Greek
                iota(0x37A, 0x37F),
                iota(0x384, 0x38A),
                iota(0x38C, 0x38C),
                iota(0x38E, 0x3A1),
                // Greek, Cyrillic, a bit of Armenian
                iota(0x3A3, 0x52F),
                // Armenian
                iota(0x531, 0x556),
                iota(0x559, 0x55F),
                // Arabic
                iota(0xFBD3, 0xFD3F),
                iota(0xFD50, 0xFD8F),
                iota(0xFD92, 0xFDC7),
                // Linear B, included because it's a high character set
                iota(0x1003C, 0x1003D),
                iota(0x1003F, 0x1004D),
                iota(0x10050, 0x1005D),
                iota(0x10080, 0x100FA),
                // Emoji
                iota(0x1F300, 0x1F6D4)
            )
            .map!(a => cast(dchar)a)
            .array;
        numCharsInCharSet = charset.length;
    }

    T gen(ref Random gen)
    {
        static assert(low <= high);
        import std.range.primitives : ElementType;
        import std.array : appender;
        import std.utf : encode;

        if(_index < frontLoaded.length) {
            value = frontLoaded[_index++];
            return value;
        }

        auto app = appender!T();
        app.reserve(high);
        size_t numElems = uniform!("[]")(low, high, gen);
        static if ((ElementType!T).sizeof == 1)
        {
            char[4] buf;
        }
        else static if ((ElementType!T).sizeof == 2)
        {
            wchar[2] buf;
        }
        else
        {
            dchar[1] buf;
        }

        size_t appLength = 0;
        while (appLength < numElems)
        {
            size_t charIndex = uniform!("[)")(0, charset.length, gen);
            auto len = encode(buf, charset[charIndex]);
            appLength += len;
            if (appLength > high) break;
            app.put(buf[0..len]);
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

private:

    int _index;

    T[] frontLoaded() @safe pure nothrow const {
        import std.algorithm: filter;
        import std.array: array;
        T[] values = ["", "a", "é"];
        return values.filter!(a => a.length >= low && a.length <= high).array;
    }
}


/// DITTO This random $(D string)s only consisting of ASCII character
struct GenASCIIString(size_t low = 1, size_t high = 32)
{
    import std.random: Random;

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
        import std.random: uniform;

        if(_index < frontLoaded.length) {
            value = frontLoaded[_index++];
            return value;
        }

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

private:

    int _index;

    string[] frontLoaded() @safe pure nothrow const {
        return ["", "a"];
    }
}



struct Gen(T, size_t low = 1, size_t high = 1024)
    if(from!"std.range.primitives".isInputRange!T && !from!"std.traits".isSomeString!T)
{

    import std.traits: Unqual, isIntegral, isFloatingPoint;
    import std.range: ElementType;
    import std.random: Random;

    alias Value = T;
    alias E = Unqual!(ElementType!T);

    T value;
    Gen!E elementGen;

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
    T[] frontLoaded() @safe nothrow {
        T[] ret = [[]];
        return ret;
    }

    T genArray(ref Random rnd) {
        import std.array: appender;
        import std.random: uniform;

        immutable length = uniform(low, high, rnd);
        auto app = appender!T;
        app.reserve(length);
        foreach(i; 0 .. length) {
            app.put(elementGen.gen(rnd));
        }

        return app.data;
    }
}

static assert(isGen!(Gen!(int[])));


struct Gen(T) if(is(T == bool)) {
    import std.random: Random;

    bool value;
    alias value this;

    bool gen(ref Random rnd) @safe {
        import std.random: uniform;
        value = [false, true][uniform(0, 2, rnd)];
        return value;
    }
}


struct Gen(T, T low = minimum!T, T high = maximum!T) if (from!"std.traits".isSomeChar!T)
{
    private static T[] frontLoaded() @safe pure nothrow { return []; }
    mixin GenNumeric!(T, low, high);
}


private template AggregateTuple(T...) {
    import unit_threaded.randomized.random: ParameterToGen;
    import std.meta: staticMap;
    alias AggregateTuple = staticMap!(ParameterToGen, T);
}

struct Gen(T) if(from!"std.traits".isAggregateType!T) {

    import std.traits: Fields;
    import std.random: Random;

    AggregateTuple!(Fields!T) generators;

    alias Value = T;
    Value value;

    T gen(ref Random rnd) @safe {
        static if(is(T == class))
            if(value is null)
                value = new T;

        foreach(i, ref g; generators) {
            value.tupleof[i] = g.gen(rnd);
        }

        return value;
    }

    inout(T) opCall() inout {
        return this.value;
    }

    alias opCall this;

}
