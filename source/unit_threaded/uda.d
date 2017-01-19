module unit_threaded.uda;

import unit_threaded.meta;
import std.traits;
import std.meta;

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template HasAttribute(alias module_, string member, alias attribute) {
    mixin(importMember!module_(member));

    static if(!__traits(compiles, __traits(getAttributes, mixin(member))))
        enum HasAttribute = false;
    else {
        enum isAttribute(alias T) = is(TypeOf!T == attribute);
        alias attrs = Filter!(isAttribute, __traits(getAttributes, mixin(member)));

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



unittest {
    import unit_threaded.attrs;
    import unit_threaded.tests.module_with_attrs;
    import std.traits: hasUDA;

    //check for value UDAs
    static assert(HasAttribute!(unit_threaded.tests.module_with_attrs, "testAttrs", HiddenTest));
    static assert(HasAttribute!(unit_threaded.tests.module_with_attrs, "testAttrs", ShouldFail));
    static assert(!HasAttribute!(unit_threaded.tests.module_with_attrs, "testAttrs", Name));

    //check for non-value UDAs
    static assert(HasAttribute!(unit_threaded.tests.module_with_attrs, "testAttrs", SingleThreaded));
    static assert(!HasAttribute!(unit_threaded.tests.module_with_attrs, "testAttrs", DontTest));

    static assert(HasAttribute!(unit_threaded.tests.module_with_attrs, "testValues", ShouldFail));
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


///
unittest {
    import unit_threaded.attrs;
    @Types!(int, float) int i;
    static assert(HasTypes!i);
    static assert(is(GetTypes!i == AliasSeq!(int, float)));

}

// copy of recent hasUDA from Phobos here because old
// compilers will fail otherwise

enum hasUtUDA(alias symbol, alias attribute) = getUtUDAs!(symbol, attribute).length > 0;

template getUtUDAs(alias symbol, alias attribute)
{
    import std.meta : Filter;

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

unittest {
    import unit_threaded.attrs;
    import unit_threaded.tests.module_with_attrs;
    import std.traits: hasUDA;

    static assert(hasUtUDA!(unit_threaded.tests.module_with_attrs.testOtherAttrs, ShouldFailWith));
    static assert(hasUtUDA!(unit_threaded.tests.module_with_attrs.testOtherAttrs, ShouldFailWith!Exception));
    static assert(!hasUtUDA!(unit_threaded.tests.module_with_attrs.testOtherAttrs, ShouldFailWith!Throwable));
}
