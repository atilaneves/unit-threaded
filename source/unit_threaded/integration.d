/**
 * This module implements functionality helpful for writing integration tests
 * as opposed to the unit variety where unit-tests are defined as not
 * having global side-effects. In constrast, this module implements
 * assertions that check for global side-effects such as writing to the
 * file system.
 */

module unit_threaded.integration;

import unit_threaded.should;

extern(C) char* mkdtemp(char*);

shared static this() {
    import std.file;
    if(!Sandbox.sandboxPath.exists) return;

    foreach(entry; dirEntries(Sandbox.sandboxPath, SpanMode.shallow)) {
        if(isDir(entry.name)) {
            rmdirRecurse(entry);
        }
    }
}


@safe:

/**
 Responsible for creating a temporary directory to serve as a sandbox where
 files can be created, written to or deleted.
 */
struct Sandbox {
    import std.path;

    enum defaultSandboxPath = buildPath("tmp", "unit-threaded");
    static string sandboxPath = defaultSandboxPath;
    string testPath;

    /// Instantiate a Sandbox object
    static Sandbox opCall() {
        Sandbox ret;
        ret.testPath = newTestDir;
        return ret;
    }

    ///
    @safe unittest {
        auto sb = Sandbox();
        assert(sb.testPath != "");
    }

    static void setPath(string path) {
        import std.file;
        sandboxPath = path;
        if(!sandboxPath.exists) () @trusted { mkdirRecurse(sandboxPath); }();
    }

    ///
    @safe unittest {
        import std.file;
        import std.path;

        Sandbox.sandboxPath.shouldEqual(defaultSandboxPath);

        immutable newPath = buildPath("foo", "bar", "baz");
        assert(!newPath.exists);
        Sandbox.setPath(newPath);
        assert(newPath.exists);
        scope(exit) () @trusted { rmdirRecurse("foo"); }();
        Sandbox.sandboxPath.shouldEqual(newPath);

        with(immutable Sandbox()) {
            writeFile("newPath.txt");
            assert(buildPath(newPath, testPath, "newPath.txt").exists);
        }

        Sandbox.resetPath;
        Sandbox.sandboxPath.shouldEqual(defaultSandboxPath);
    }

    static void resetPath() {
        sandboxPath = defaultSandboxPath;
    }

    /// Write a file to the sandbox
    void writeFile(in string fileName, in string output = "") const {
        import std.stdio;
        import std.path;
        File(buildPath(testPath, fileName), "w").writeln(output);
    }

    /// Write a file to the sanbox
    void writeFile(in string fileName, in string[] lines) const {
        import std.array;
        writeFile(fileName, lines.join("\n"));
    }

    ///
    @safe unittest {
        import std.file;
        import std.path;

        with(immutable Sandbox()) {
            assert(!buildPath(testPath, "foo.txt").exists);
            writeFile("foo.txt");
            assert(buildPath(testPath, "foo.txt").exists);
        }
    }

    /// Assert that a file exists in the sandbox
    void shouldExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file;
        import std.path;
        fileName = buildPath(testPath, fileName);
        if(!fileName.exists)
            fail("Expected " ~ fileName ~ " to exist but it didn't", file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            shouldExist("bar.txt").shouldThrow;
            writeFile("bar.txt");
            shouldExist("bar.txt");
        }
    }

    /// Assert that a file does not exist in the sandbox
    void shouldNotExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file;
        import std.path;
        fileName = buildPath(testPath, fileName);
        if(fileName.exists)
            fail("Expected " ~ fileName ~ " to not exist but it did", file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            shouldNotExist("baz.txt");
            writeFile("baz.txt");
            shouldNotExist("baz.txt").shouldThrow;
        }
    }

    /// read a file in the test sandbox and verify its contents
    void shouldEqualLines(in string fileName, in string[] lines,
                          string file = __FILE__, size_t line = __LINE__) const @trusted {
        import std.file;
        import std.string;

        readText(buildPath(testPath, fileName)).chomp.split("\n")
            .shouldEqual(lines, file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            writeFile("lines.txt", ["foo", "toto"]);
            shouldEqualLines("lines.txt", ["foo", "bar"]).shouldThrow;
            shouldEqualLines("lines.txt", ["foo", "toto"]);
        }
    }

private:

    static string newTestDir() {
        import std.conv;
        import std.path;
        import std.algorithm;
        import std.exception;
        import std.file;
        import core.stdc.string;
        import core.stdc.errno;

        if(!sandboxPath.exists) {
            () @trusted { mkdirRecurse(sandboxPath); }();
        }

        char[100] template_;
        std.algorithm.copy(buildPath(sandboxPath, "XXXXXX") ~ '\0', template_[]);

        auto ret = () @trusted { return mkdtemp(&template_[0]).to!string; }();
        enforce(ret != "", "Failed to create temporary directory name: " ~
                () @trusted { return strerror(errno).to!string; }());

        return ret.absolutePath;
    }

}
