module unit_threaded.ut.traits;

import unit_threaded.runner.traits;

unittest {
    import unit_threaded.runner.attrs;
    import unit_threaded.ut.modules.module_with_attrs;
    import std.traits: hasUDA;

    //check for value UDAs
    static assert(HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testAttrs", HiddenTest));
    static assert(HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testAttrs", ShouldFail));
    static assert(!HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testAttrs", Name));

    //check for non-value UDAs
    static assert(HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testAttrs", SingleThreaded));
    static assert(!HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testAttrs", DontTest));

    static assert(HasAttribute!(unit_threaded.ut.modules.module_with_attrs, "testValues", ShouldFail));
}

unittest {
    import unit_threaded.runner.attrs;
    import std.meta;

    @Types!(int, float) int i;
    static assert(HasTypes!i);
    static assert(is(GetTypes!i == AliasSeq!(int, float)));

}

unittest {
    import unit_threaded.runner.attrs;
    import unit_threaded.ut.modules.module_with_attrs;
    import std.traits: hasUDA;

    static assert(hasUtUDA!(unit_threaded.ut.modules.module_with_attrs.testOtherAttrs, ShouldFailWith));
    static assert(hasUtUDA!(unit_threaded.ut.modules.module_with_attrs.testOtherAttrs, ShouldFailWith!Exception));
    static assert(!hasUtUDA!(unit_threaded.ut.modules.module_with_attrs.testOtherAttrs, ShouldFailWith!Throwable));
}
