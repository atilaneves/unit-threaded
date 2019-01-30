/**
   Helper functions for dealing with UDAs, written before hasUDA and
   others were added to Phobos.
 */
module unit_threaded.runner.traits;

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 * For reasons I don't yet understand, it doesn't seem replaceable
 * with std.traits.getUDAs
 */
template GetAttributes(alias member, Attrs...) if(Attrs.length == 1) {
    import std.meta: Filter;

    alias A = Attrs[0];

    private template TypeOf(alias T) {
        static if(__traits(compiles, typeof(T))) {
            alias TypeOf = typeof(T);
        } else {
            alias TypeOf = T;
        }
    }

    enum isAttribute(alias T) = is(TypeOf!T == A);
    alias GetAttributes = Filter!(isAttribute, __traits(getAttributes, member));
}
