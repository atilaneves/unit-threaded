/**
This module implements a $(LINK2 http://dlang.org/template-mixin.html,
template mixin) containing a program to search a list of directories
for all .d files therein, then writes a D program to run all unit
tests in those files using unit_threaded. The program
implemented by this mixin only writes out a D file that itself must be
compiled and run.

To use this as a runnable program, simply mix in and compile:
-----
#!/usr/bin/rdmd
import unit_threaded;
mixin genUtMain;
-----

Or just use rdmd with the included gen_ut_main,
which does the above. The examples below use the second option.

By default, genUtMain will look for unit tests in a $(D tests)
folder and write a program out to a file named $(D ut.d). To change
the file to write to, use the $(D -f) option. To change what
directories to look in, simply pass them in as the remaining
command-line arguments.

Examples:
-----
# write ut.d that finds unit tests from files in the tests directory
rdmd $PHOBOS/std/experimental/testing/gen_ut_main.d

# write foo.d that finds unit tests from the src and other directories
rdmd $PHOBOS/std/experimental/testing/gen_ut_main.d -f foo.d src other
-----

The resulting $(D ut.d) file (or as named by the $(D -f) option) is
also a program that must be compiled and, when run, will run the unit
tests found. By default, it will run all tests. To run one test or
all tests in a particular package, pass them in as command-line arguments.
The $(D -h) option will list all command-line options.

Examples (assuming the generated file is called $(D ut.d)):
-----
rdmd -unittest ut.d # run all tests
rdmd -unittest ut.d tests.foo tests.bar # run all tests from these packages
rdmd ut.d -h # list command-line options
-----
*/

module unit_threaded.runtime;

import std.stdio;
import std.array : replace, array, join;
import std.conv : to;
import std.algorithm : map, filter, startsWith, endsWith, remove;
import std.string: strip;
import std.exception : enforce;
import std.file : exists, DirEntry, dirEntries, isDir, SpanMode, tempDir, getcwd, dirName, mkdirRecurse;
import std.path : buildNormalizedPath, buildPath, baseName, relativePath, dirSeparator;


mixin template genUtMain() {

    int main(string[] args) {
        try {
            writeUtMainFile(args);
            return 0;
        } catch(Exception ex) {
            import std.stdio: stderr;
            stderr.writeln(ex.msg);
            return 1;
        }
    }
}


struct Options {
    bool verbose;
    string fileName;
    string[] dirs;
    bool help;
    bool showVersion;
    string[] includes;

    bool earlyReturn() @safe pure nothrow const {
        return help || showVersion;
    }
}


Options getGenUtOptions(string[] args) {
    import std.getopt;

    Options options;
    auto getOptRes = getopt(
        args,
        "verbose|v", "Verbose mode.", &options.verbose,
        "file|f", "The filename to write. Will use a temporary if not set.", &options.fileName,
        "I", "Import paths as would be passed to the compiler", &options.includes,
        "version", "Show version.", &options.showVersion,
        );

    if (getOptRes.helpWanted) {
        defaultGetoptPrinter("Usage: gen_ut_main [options] [testDir1] [testDir2]...", getOptRes.options);
        options.help = true;
        return options;
    }

    if (options.showVersion) {
        writeln("unit_threaded.runtime version v0.5.7");
        return options;
    }

    options.dirs = args.length <= 1 ? ["."] : args[1 .. $];

    if (options.verbose) {
        writeln(__FILE__, ": finding all test cases in ", options.dirs);
    }

    return options;
}


DirEntry[] findModuleEntries(in Options options) {

    DirEntry[] modules;
    foreach (dir; options.dirs) {
        enforce(isDir(dir), dir ~ " is not a directory name");
        auto entries = dirEntries(dir, "*.d", SpanMode.depth);
        auto normalised = entries.map!(a => buildNormalizedPath(a.name));

        modules ~= normalised.
            map!(a => DirEntry(a)).array;
    }

    return modules;
}


string[] findModuleNames(in Options options) {
    import std.path : dirSeparator, stripExtension;

    // if a user passes -Isrc and a file is called src/foo/bar.d,
    // the module name should be foo.bar, not src.foo.bar,
    // so this function subtracts import path options
    string relativeToImportDirs(string path) {
        foreach(string importPath; options.includes) {
            if(!importPath.endsWith(dirSeparator)) importPath ~= dirSeparator;
            if(path.startsWith(importPath)) {
                return path.replace(importPath, "");
            }
        }

        return path;
    }

    return findModuleEntries(options).
        filter!(a => a.baseName != "package.d" && a.baseName != "reggaefile.d").
        map!(a => relativeToImportDirs(a.name)).
        map!(a => replace(a.stripExtension, dirSeparator, ".")).
        array;
}

string writeUtMainFile(string[] args) {
    auto options = getGenUtOptions(args);
    return writeUtMainFile(options);
}

string writeUtMainFile(Options options) {
    if (options.earlyReturn) {
        return options.fileName;
    }

    return writeUtMainFile(options, findModuleNames(options));
}

private string writeUtMainFile(Options options, in string[] modules) {
    if (!options.fileName) {
        options.fileName = buildPath(tempDir, getcwd[1..$], "ut.d");
    }

    if(!haveToUpdate(options, modules)) {
        if(options.verbose) writeln("Not writing to ", options.fileName, ": no changes detected");
        return options.fileName;
    } else {
        if(options.verbose) writeln("Writing to unit test main file ", options.fileName);
    }

    const dirName = options.fileName.dirName;
    dirName.exists || mkdirRecurse(dirName);


    auto wfile = File(options.fileName, "w");
    wfile.write(modulesDbList(modules));
    wfile.writeln(q{
//Automatically generated by unit_threaded.gen_ut_main, do not edit by hand.
import std.stdio;
import unit_threaded;
});

    wfile.writeln("int main(string[] args)");
    wfile.writeln("{");
    wfile.writeln(`    writeln("\nAutomatically generated file ` ~
                  options.fileName.replace("\\", "\\\\") ~ `");`);
    wfile.writeln("    writeln(`Running unit tests from dirs " ~ options.dirs.to!string ~ "`);");

    immutable indent = "                     ";
    wfile.writeln("    return runTests!(\n" ~
                  modules.map!(a => indent ~ `"` ~ a ~ `"`).join(",\n") ~
                  "\n" ~ indent ~ ")\n" ~ indent ~ "(args);");
    wfile.writeln("}");
    wfile.close();

    return options.fileName;
}


private bool haveToUpdate(in Options options, in string[] modules) {
    if (!options.fileName.exists) {
        return true;
    }

    auto file = File(options.fileName);
    return file.readln.strip != modulesDbList(modules);
}


//used to not update the file if the file list hasn't changed
private string modulesDbList(in string[] modules) @safe pure nothrow {
    return "//" ~ modules.join(",");
}
