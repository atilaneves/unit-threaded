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

    static string sandboxPath = buildPath("tmp", "unit-threaded");
    string testPath;

    static Sandbox opCall() {
        Sandbox ret;
        ret.testPath = newTestDir;
        return ret;
    }

    unittest {
        auto sb = Sandbox();
        assert(sb.testPath != "");
    }

    void writeFile(in string fileName, in string output = "") const {
        import std.stdio;
        import std.path;
        File(buildPath(testPath, fileName), "w").writeln(output);
    }

    void writeFile(in string fileName, in string[] lines) const {
        import std.array;
        writeFile(fileName, lines.join("\n"));
    }

    unittest {
        import std.file;
        import std.path;

        with(immutable Sandbox()) {
            assert(!buildPath(testPath, "foo.txt").exists);
            writeFile("foo.txt");
            assert(buildPath(testPath, "foo.txt").exists);
        }
    }

    void shouldExist(string fileName, in string file = __FILE__, in size_t line = __LINE__) const {
        import std.file;
        import std.path;
        fileName = buildPath(testPath, fileName);
        if(!fileName.exists)
            fail("Expected " ~ fileName ~ " to exist but it didn't", file, line);
    }

    unittest {
        with(immutable Sandbox()) {
            shouldExist("bar.txt").shouldThrow;
            writeFile("bar.txt");
            shouldExist("bar.txt");
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
