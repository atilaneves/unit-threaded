/**
   Helper functions for dealing with UDAs, written before hasUDA and
   others were added to Phobos.
 */
module unit_threaded.runner.traits;

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template GetAttributes(alias module_, string member, A) {
    import unit_threaded.runner.meta: importMember;
    import std.meta: Filter;

    private template TypeOf(alias T) {
        static if(__traits(compiles, typeof(T))) {
            alias TypeOf = typeof(T);
        } else {
            alias TypeOf = T;
        }
    }

    mixin(importMember!module_(member));
    enum isAttribute(alias T) = is(TypeOf!T == A);
    alias GetAttributes = Filter!(isAttribute, __traits(getAttributes, mixin(member)));
}
