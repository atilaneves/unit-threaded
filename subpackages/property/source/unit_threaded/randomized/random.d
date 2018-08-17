module unit_threaded.randomized.random;


/** This type will generate a $(D Gen!T) for all passed $(D T...).
    Every call to $(D genValues) will call $(D gen) of all $(D Gen) structs
    present in $(D values). The member $(D values) can be passed to every
    function accepting $(D T...).
*/
struct RndValueGen(T...)
{
    import std.meta : staticMap;
    import std.random: Random;

    /* $(D Values) is a collection of $(D Gen) types created through
       $(D ParameterToGen) of passed $(T ...).
    */
    static if(is(typeof(T[0]) == string[])) {
        alias generators = T[1 .. $];
        string[] parameterNames = T[0];
    } else {
        alias generators = T;
        string[T.length] parameterNames;
    }

    alias Values = staticMap!(ParameterToGen, generators);

    /// Ditto
    Values values;

    /* The constructor accepting the required random number generator.
       Params:
       rnd = The required random number generator.
    */
    this(Random* rnd) @safe
    {
        this.rnd = rnd;
    }

    this(ref Random rnd) {
        this.rnd = &rnd;
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
        assert(rnd !is null);
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


/** A template that turns a $(D T) into a $(D Gen!T) unless $(D T) is
    already a $(D Gen) or no $(D Gen) for given $(D T) is available.
*/
template ParameterToGen(T)
{
    import unit_threaded.randomized.gen: isGen, Gen;
    static if (isGen!T)
        alias ParameterToGen = T;
    else static if (is(T : GenASCIIString!(S), S...))
        alias ParameterToGen = T;
    else {
        static assert(__traits(compiles, Gen!T),
                      "ParameterToGen does not handle " ~ T.stringof);
        alias ParameterToGen = Gen!T;
    }
}
