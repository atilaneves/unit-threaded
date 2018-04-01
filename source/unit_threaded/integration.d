/**
 * This module implements functionality helpful for writing integration tests
 * as opposed to the unit variety where unit-tests are defined as not
 * having global side-effects. In constrast, this module implements
 * assertions that check for global side-effects such as writing to the
 * file system.
 */

module unit_threaded.integration;

version(Windows) {
    extern(C) int mkdir(char*);
    extern(C) char* mktemp(char* template_);
    char* mkdtemp(char* t) {
        char* result = mktemp(t);
        if (result is null) return null;
        if (mkdir(result)) return null;
        return result;
    }
} else {
    extern(C) char* mkdtemp(char* template_);
}


shared static this() {
    import std.file: exists, dirEntries, SpanMode, isDir, rmdirRecurse;

    if(!Sandbox.sandboxesPath.exists) return;

    foreach(entry; dirEntries(Sandbox.sandboxesPath, SpanMode.shallow)) {
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

    enum defaultSandboxesPath = buildPath("tmp", "unit-threaded");
    static string sandboxesPath = defaultSandboxesPath;
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
        import std.file: exists, mkdirRecurse;
        sandboxesPath = path;
        if(!sandboxesPath.exists) () @trusted { mkdirRecurse(sandboxesPath); }();
    }

    ///
    @safe unittest {
        import std.file: exists, rmdirRecurse;
        import std.path: buildPath;
        import unit_threaded.should;

        Sandbox.sandboxesPath.shouldEqual(defaultSandboxesPath);

        immutable newPath = buildPath("foo", "bar", "baz");
        assert(!newPath.exists);
        Sandbox.setPath(newPath);
        assert(newPath.exists);
        scope(exit) () @trusted { rmdirRecurse("foo"); }();
        Sandbox.sandboxesPath.shouldEqual(newPath);

        with(immutable Sandbox()) {
            writeFile("newPath.txt");
            assert(buildPath(newPath, testPath, "newPath.txt").exists);
        }

        Sandbox.resetPath;
        Sandbox.sandboxesPath.shouldEqual(defaultSandboxesPath);
    }

    static void resetPath() {
        sandboxesPath = defaultSandboxesPath;
    }

    /// Write a file to the sandbox
    void writeFile(in string fileName, in string output = "") const {
        import std.stdio: File;
        import std.path: buildPath, dirName;
        import std.file: mkdirRecurse;

        () @trusted { mkdirRecurse(buildPath(testPath, fileName.dirName)); }();
        File(buildPath(testPath, fileName), "w").writeln(output);
    }

    /// Write a file to the sanbox
    void writeFile(in string fileName, in string[] lines) const {
        import std.array;
        writeFile(fileName, lines.join("\n"));
    }

    ///
    @safe unittest {
        import std.file: exists;
        import std.path: buildPath;

        with(immutable Sandbox()) {
            assert(!buildPath(testPath, "foo.txt").exists);
            writeFile("foo.txt");
            assert(buildPath(testPath, "foo.txt").exists);
        }
    }

    @safe unittest {
        import std.file: exists;
        import std.path: buildPath;

        with(immutable Sandbox()) {
            writeFile("foo/bar.txt");
            assert(buildPath(testPath, "foo", "bar.txt").exists);
        }
    }

    /// Assert that a file exists in the sandbox
    void shouldExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file;
        import std.path;
        import unit_threaded.should: fail;

        fileName = buildPath(testPath, fileName);
        if(!fileName.exists)
            fail("Expected " ~ fileName ~ " to exist but it didn't", file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            import unit_threaded.should;

            shouldExist("bar.txt").shouldThrow;
            writeFile("bar.txt");
            shouldExist("bar.txt");
        }
    }

    /// Assert that a file does not exist in the sandbox
    void shouldNotExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file: exists;
        import std.path: buildPath;
        import unit_threaded.should;

        fileName = buildPath(testPath, fileName);
        if(fileName.exists)
            fail("Expected " ~ fileName ~ " to not exist but it did", file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            import unit_threaded.should;

            shouldNotExist("baz.txt");
            writeFile("baz.txt");
            shouldNotExist("baz.txt").shouldThrow;
        }
    }

    /// read a file in the test sandbox and verify its contents
    void shouldEqualLines(in string fileName, in string[] lines,
                          string file = __FILE__, size_t line = __LINE__) const @trusted {
        import std.file: readText;
        import std.string: chomp, splitLines;
        import unit_threaded.should;

        readText(buildPath(testPath, fileName)).chomp.splitLines
            .shouldEqual(lines, file, line);
    }

    ///
    @safe unittest {
        with(immutable Sandbox()) {
            import unit_threaded.should;

            writeFile("lines.txt", ["foo", "toto"]);
            shouldEqualLines("lines.txt", ["foo", "bar"]).shouldThrow;
            shouldEqualLines("lines.txt", ["foo", "toto"]);
        }
    }

    string sandboxPath() @safe @nogc pure nothrow const {
        return testPath;
    }

    string inSandboxPath(in string fileName) @safe pure nothrow const {
        import std.path: buildPath;
        return buildPath(sandboxPath, fileName);
    }

    /**
       Executing `args` should succeed
     */
    void shouldSucceed(string file = __FILE__, size_t line = __LINE__)
                      (in string[] args...)
        @safe const
    {
        import unit_threaded.should: UnitTestException;
        import std.conv: text;
        import std.array: join;

        const res = executeInSandbox(args);
        if(res.status != 0)
           throw new UnitTestException(text("Could not execute `", args.join(" "), "`:\n", res.output),
                                       file, line);
    }

    alias shouldExecuteOk = shouldSucceed;

    /**
       Executing `args` should fail
     */
    void shouldFail(string file = __FILE__, size_t line = __LINE__)
                   (in string[] args...)
        @safe const
    {
        import unit_threaded.should: UnitTestException;
        import std.conv: text;
        import std.array: join;

        const res = executeInSandbox(args);
        if(res.status == 0)
            throw new UnitTestException(
                text("`", args.join(" "), "` should have failed but didn't:\n", res.output),
                file,
                line);
    }


private:

    auto executeInSandbox(in string[] args) @safe const {
        import std.process: execute, Config;
        import std.algorithm: startsWith;
        import std.array: replace;

        const string[string] env = null;
        const config = Config.none;
        const maxOutput = size_t.max;
        const workDir = testPath;

        const executable = args[0].startsWith("./")
            ? inSandboxPath(args[0].replace("./", ""))
            : args[0];

        return execute(executable ~ args[1..$], env, config, maxOutput, workDir);
    }

    static string newTestDir() {
        import std.file: exists, mkdirRecurse;

        if(!sandboxesPath.exists) {
            () @trusted { mkdirRecurse(sandboxesPath); }();
        }

        return makeTempDir();
    }

    static string makeTempDir() {
        import std.algorithm: copy;
        import std.exception: enforce;
        import std.conv: to;
        import core.stdc.string: strerror;
        import core.stdc.errno: errno;

        char[100] template_;
        copy(buildPath(sandboxesPath, "XXXXXX") ~ '\0', template_[]);

        auto ret = () @trusted { return mkdtemp(&template_[0]).to!string; }();

        enforce(ret != "", "Failed to create temporary directory name: " ~
                () @trusted { return strerror(errno).to!string; }());

        return ret.absolutePath;
    }
}
