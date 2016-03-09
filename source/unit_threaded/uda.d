module unit_threaded.uda;

import std.traits;
import std.meta;

/**
 * For the given module, return true if this module's member has
 * the given UDA. UDAs can be types or values.
 */
template HasAttribute(alias module_, string member, alias attribute) {
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

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
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible
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

template HasTypes(alias T) {
    import unit_threaded.attrs;

    static if(__traits(compiles, __traits(getAttributes, T))) {
        enum HasTypes = Filter!(isTypesAttr, __traits(getAttributes, T)).length == 1;
    }
    else
        enum HasTypes = false;
}

template GetTypes(alias T) {
    static if(HasTypes!T)
        alias GetTypes = TemplateArgsOf!(Filter!(isTypesAttr, __traits(getAttributes, T))[0]);
    else
        alias GetTypes = AliasSeq!();
}


unittest {
    import unit_threaded.attrs;

    @Types!(int, float) int i;
    static assert(HasTypes!i);
    static assert(is(GetTypes!i == AliasSeq!(int, float)));

}
