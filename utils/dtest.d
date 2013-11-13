#!/usr/bin/rdmd

/**
 * Implements a program to search a list of directories
 * for all .d files, then writes and executes a D program
 * to run all tests contained in those files
 */

import std.stdio;
import std.file;
import std.exception;
import std.array;
import std.algorithm;
import std.path;
import std.conv;
import std.process;
import std.getopt;

/**
 * args is a filename and a list of directories to search in
 * the filename is the 1st element, the others are directories.
 */
int main(string[] args) {
    enforce(args.length >= 2, text("Usage: ", __FILE__, " <dir>..."));

    const options = getOptions(args);
    if(options.help) return 0;

    auto file = writeFile(options, findModuleNames(options.dirs));
    immutable rdmd = executeRdmd(options);
    writeln(rdmd.output);

    return rdmd.status;
}

private struct Options {
    bool debugOutput;
    string fileName;
    string[] dirs;
    string unit_threaded;
    bool help;
}

private Options getOptions(string[] args) {
    Options options;
    getopt(args,
           "debug|d", &options.debugOutput,
           "file|f", &options.fileName,
           "unit_threaded|u", &options.unit_threaded,
           "help|h", &options.help
        );

    if(options.help) {
        writeln("Usage: ", __FILE__, " [options] <dir1> [dir2]...\n",
                "Options:\n",
                "    -h/--help: help\n",
                "    -u/--unit_threaded: directory location of the unit_threaded library\n",
                "    -d/--debug: print debug information\n",
                "    -f/--file: file name to write to\n",
                "\nThis will run all unit tests encountered in the given directories.\n",
                "It does this by scanning them and writing a D source file that imports\n",
                "all of them then running that source file with rdmd. By default the\n",
                "source file is a randomly named temporary file but that can be changed\n",
                "with the -f option. If the unit_threaded library is not in the default\n",
                "search paths then it must be specified with the -u option.\n\n");
    }

    if(!options.fileName) options.fileName = createFileName(); //random filename
    options.dirs = args[1..$];
    if(options.debugOutput) writeln(__FILE__, ": finding all test cases in ", options.dirs);
    return options;
}

private string createFileName() {
    import std.random;
    import std.ascii : letters, digits;
    immutable nameLength = uniform(10, 20);
    immutable alphanums = letters ~ digits;

    string fileName = "" ~ letters[uniform(0, letters.length)];
    foreach(i; 0 .. nameLength) {
        fileName ~= alphanums[uniform(0, alphanums.length)];
    }

    return buildPath(tempDir(),  fileName ~ ".d");
}

auto findModuleEntries(in string[] dirs) {
    DirEntry[] modules;
    foreach(dir; dirs) {
        enforce(isDir(dir), dir ~ " is not a directory name");
        auto entries = dirEntries(dir, "*.d", SpanMode.depth);
        auto normalised = map!(a => DirEntry(buildNormalizedPath(a)))(entries);
        modules ~= array(normalised);
        writeln("modules now ", modules);
    }
    return modules;
}

auto findModuleNames(in string[] dirs) {
    //cut off extension
    return array(map!(a => replace(a.name[0 .. $-2], dirSeparator, "."))(findModuleEntries(dirs)));
}

private auto writeFile(in Options options, in string[] modules) {
    auto filew = File(options.fileName, "w");
    filew.writeln("import unit_threaded.runner;");
    filew.writeln("import std.stdio;");
    filew.writeln("");
    filew.writeln("int main(string[] args) {");
    filew.writeln(`    writeln("\nAutomatically generated file ` ~ options.fileName ~ `");`);
    filew.writeln("    writeln(`Running unit tests from dirs " ~ to!string(options.dirs) ~ "\n`);");
    filew.writeln("    return runTests!(" ~ join(map!(a => `"` ~ a ~ `"`)(modules), ", ") ~ ")(args);");
    filew.writeln("}");
    filew.close();

    auto filer = File(options.fileName, "r");
    printFile(options, filer);
    return filer;
}

private void printFile(in Options options, File file) {
    if(!options.debugOutput) return;
    writeln("Executing this code:\n");
    foreach(line; file.byLine()) {
        writeln(line);
    }
    writeln();
    file.rewind();
}

private auto executeRdmd(in Options options) {
    immutable includeDirs = options.dirs ~ options.unit_threaded ? [options.unit_threaded] : [];
    immutable includes = join(map!(a => "-I" ~ a)(includeDirs), ", ");
    auto rdmdArgs = [ "rdmd" ] ~ includes ~ options.fileName;
    if(options.debugOutput) writeln("Executing: ", join(rdmdArgs, ", "));
    return execute(rdmdArgs);
}
