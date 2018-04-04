module unit_threaded.ut.runtime;

import unit_threaded.runtime;

@("issue 40")
unittest {
    import unit_threaded.should;
    import std.path;
    dubFilesToAbsPaths("", ["foo/bar/package.d"]).shouldEqual(
        [buildPath("foo", "bar")]);
}
