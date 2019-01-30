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
