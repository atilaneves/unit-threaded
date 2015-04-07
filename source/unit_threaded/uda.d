module unit_threaded.uda;

import std.traits;
import std.typetuple;

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template HasAttribute(alias member, alias attribute) {
    enum isAttribute(alias T) = is(TypeOf!T == attribute);
    alias attrs = Filter!(isAttribute, __traits(getAttributes, member));

    static if(attrs.length == 0) {
        enum HasAttribute = false;
    } else {
        enum HasAttribute = true;
    }
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

    //check for value UDAs
    static assert(HasAttribute!(testAttrs, HiddenTest));
    static assert(HasAttribute!(testAttrs, ShouldFail));
    static assert(!HasAttribute!(testAttrs, Name));

    //check for non-value UDAs
    static assert(HasAttribute!(testAttrs, SingleThreaded));
}
