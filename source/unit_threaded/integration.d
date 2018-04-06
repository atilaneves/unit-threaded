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
        version(unitUnthreaded)
            return mkdtempImpl(t);
        else {
            synchronized {
                return mkdtempImpl(t);
            }
        }
    }

    char* mkdtempImpl(char* t) {
        char* result = mktemp(t);

        if(result is null) return null;
        if (mkdir(result)) return null;

        return result;
    }

} else {
    extern(C) char* mkdtemp(char* template_);
}


shared static this() {
    import std.file: exists, rmdirRecurse;

    if(Sandbox.sandboxesPath.exists)
        rmdirRecurse(Sandbox.sandboxesPath);
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


    static void setPath(string path) {
        import std.file: exists, mkdirRecurse;
        sandboxesPath = path;
        if(!sandboxesPath.exists) () @trusted { mkdirRecurse(sandboxesPath); }();
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


    /// Assert that a file exists in the sandbox
    void shouldExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file: exists;
        import std.path: buildPath;
        import unit_threaded.should: fail;

        fileName = buildPath(testPath, fileName);
        if(!fileName.exists)
            fail("Expected " ~ fileName ~ " to exist but it didn't", file, line);
    }

    /// Assert that a file does not exist in the sandbox
    void shouldNotExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file: exists;
        import std.path: buildPath;
        import unit_threaded.should: fail;

        fileName = buildPath(testPath, fileName);
        if(fileName.exists)
            fail("Expected " ~ fileName ~ " to not exist but it did", file, line);
    }

    /// read a file in the test sandbox and verify its contents
    void shouldEqualContent(in string fileName, in string content,
                            in string file = __FILE__, in size_t line = __LINE__)
        const
    {
        import std.file: readText;
        import std.string: chomp, splitLines;
        import unit_threaded.should: shouldEqual;

        readText(buildPath(testPath, fileName)).shouldEqual(content, file, line);
    }

    /// read a file in the test sandbox and verify its contents
    void shouldEqualLines(in string fileName, in string[] lines,
                          string file = __FILE__, size_t line = __LINE__)
        const
    {
        import std.file: readText;
        import std.string: chomp, splitLines;
        import unit_threaded.should: shouldEqual;

        readText(buildPath(testPath, fileName)).chomp.splitLines
            .shouldEqual(lines, file, line);
    }

    // `fileName` should contain `needle`
    void fileShouldContain(in string fileName,
                           in string needle,
                           in string file = __FILE__,
                           in size_t line = __LINE__)
    {
        import std.file: readText;
        import unit_threaded.should: shouldBeIn;
        needle.shouldBeIn(readText(inSandboxPath(fileName)), file, line);
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
        import std.string: fromStringz;
        import core.stdc.string: strerror;
        import core.stdc.errno: errno;

        char[2048] template_;
        copy(buildPath(sandboxesPath, "XXXXXX") ~ '\0', template_[]);

        auto path = () @trusted { return mkdtemp(&template_[0]).to!string; }();

        enforce(path != "",
                "\n" ~
                "Failed to create temporary directory name using template '" ~
                () @trusted { return fromStringz(&template_[0]); }() ~ "': " ~
                () @trusted { return strerror(errno).to!string; }());

        return path.absolutePath;
    }
}
