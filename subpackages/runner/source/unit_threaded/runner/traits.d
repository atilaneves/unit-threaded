/**
   Helper functions for dealing with UDAs, written before hasUDA and
   others were added to Phobos.
 */
module unit_threaded.runner.traits;

private template Identity(T...) if(T.length > 0) {
    static if(__traits(compiles, { alias x = T[0]; }))
        alias Identity = T[0];
    else
        enum Identity = T[0];
}


/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template HasAttribute(alias module_, string moduleMember, alias attribute) {
    import unit_threaded.runner.meta: importMember;
    import std.meta: Filter;

    alias member = Identity!(__traits(getMember, module_, moduleMember));

    static if(!__traits(compiles, __traits(getAttributes, member)))
        enum HasAttribute = false;
    else {
        enum isAttribute(alias T) = is(TypeOf!T == attribute);
        alias attrs = Filter!(isAttribute, __traits(getAttributes, member));

        static assert(attrs.length == 0 || attrs.length == 1,
                      text("Maximum number of attributes is 1 for ", attribute));

        static if(attrs.length == 0) {
            enum HasAttribute = false;
        } else {
            enum HasAttribute = true;
        }
    }
}

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template GetAttributes(alias module_, string member, A) {
    import unit_threaded.runner.meta: importMember;
    import std.meta: Filter;

    mixin(importMember!module_(member));
    enum isAttribute(alias T) = is(TypeOf!T == A);
    alias GetAttributes = Filter!(isAttribute, __traits(getAttributes, mixin(member)));
}


/**
 * Utility to allow checking UDAs regardless of whether the template
 * parameter is or has a type
 */
private template TypeOf(alias T) {
    static if(__traits(compiles, typeof(T))) {
        alias TypeOf = typeof(T);
    } else {
        alias TypeOf = T;
    }
}


template isTypesAttr(alias T) {
    import unit_threaded.runner.attrs;
    enum isTypesAttr = is(T) && is(T:Types!U, U...);
}
