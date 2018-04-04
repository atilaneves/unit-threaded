/**
   Helper functions for dealing with UDAs, written before hasUDA and
   others were added to Phobos.
 */
module unit_threaded.uda;

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
    import unit_threaded.meta: importMember;
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
    import unit_threaded.meta: importMember;
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
    import unit_threaded.attrs;
    enum isTypesAttr = is(T) && is(T:Types!U, U...);
}


/*
 @Types is different from the other UDAs since it's a templated struct
 None of the templates above work so we special case it here
*/

/// If a test has the @Types UDA
enum HasTypes(alias T) = GetTypes!T.length > 0;

/// Returns the types in the @Types UDA associated to a test
template GetTypes(alias T) {
    import std.meta: Filter, AliasSeq;
    import std.traits: TemplateArgsOf;

    static if(!__traits(compiles, __traits(getAttributes, T))) {
        alias GetTypes = AliasSeq!();
    } else {
        alias types = Filter!(isTypesAttr, __traits(getAttributes, T));
        static if(types.length > 0)
            alias GetTypes = TemplateArgsOf!(types[0]);
        else
            alias GetTypes = AliasSeq!();
    }
}



// copy of recent hasUDA from Phobos here because old
// compilers will fail otherwise

enum hasUtUDA(alias symbol, alias attribute) = getUtUDAs!(symbol, attribute).length > 0;

template getUtUDAs(alias symbol, alias attribute)
{
    import std.meta : Filter;
    import std.traits: isInstanceOf;

    template isDesiredUDA(alias toCheck)
    {
        static if (is(typeof(attribute)) && !__traits(isTemplate, attribute))
        {
            static if (__traits(compiles, toCheck == attribute))
                enum isDesiredUDA = toCheck == attribute;
            else
                enum isDesiredUDA = false;
        }
        else static if (is(typeof(toCheck)))
        {
            static if (__traits(isTemplate, attribute))
                enum isDesiredUDA =  isInstanceOf!(attribute, typeof(toCheck));
            else
                enum isDesiredUDA = is(typeof(toCheck) == attribute);
        }
        else static if (__traits(isTemplate, attribute))
            enum isDesiredUDA = isInstanceOf!(attribute, toCheck);
        else
            enum isDesiredUDA = is(toCheck == attribute);
    }

    alias getUtUDAs = Filter!(isDesiredUDA, __traits(getAttributes, symbol));
}
