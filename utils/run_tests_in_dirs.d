#!/usr/bin/rdmd

module unit_threaded.finder;

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
    immutable fileName = createFileName(options);

    const modules = findModuleNames(options.dirs);
    auto file = writeFile(fileName, modules, options.dirs);
    printFile(options, file);

    immutable rdmd = executeRdmd(options, fileName);
    writeln(rdmd.output);
    return rdmd.status;
}

private struct Options {
    bool debugOutput;
    string fileName;
    string[] dirs;
}

private Options getOptions(string[] args) {
    Options options;
    getopt(args,
           "debug|d", &options.debugOutput,
           "file|f", &options.fileName
        );
    options.dirs = args[1..$];
    if(options.debugOutput) writeln(__FILE__, ": finding all test cases in ", options.dirs);
    return options;
}

private string createFileName(in Options options) {
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
        modules ~= array(dirEntries(dir, "*.d", SpanMode.depth));
    }
    return modules;
}

auto findModuleNames(in string[] dirs) {
    //cut off extension
    return array(map!(a => replace(a.name[0 .. $-2], dirSeparator, "."))(findModuleEntries(dirs)));
}

private auto writeFile(in string fileName, in string[] modules, in string[] dirs) {
    auto file = File(fileName, "w");
    file.writeln("import unit_threaded.runner;");
    file.writeln("import std.stdio;");
    file.writeln("");
    file.writeln("int main(string[] args) {");
    file.writeln(`    writeln("\nAutomatically generated file ` ~ fileName ~ `");`);
    file.writeln("    writeln(`Running unit tests from dirs " ~ to!string(dirs) ~ "\n`);");
    file.writeln("    return runTests!(" ~ join(map!(a => `"` ~ a ~ `"`)(modules), ", ") ~ ")(args);");
    file.writeln("}");
    file.close();

    return File(fileName, "r");
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

private auto executeRdmd(in Options options, in string fileName) {
    auto rdmdArgs = getRdmdArgs(fileName, options.dirs);
    if(options.debugOutput) writeln("Executing ", join(rdmdArgs, ", "));
    return execute(rdmdArgs);
}

private auto getRdmdArgs(in string fileName, in string[] dirs) {
    return [ "rdmd" ] ~ join(map!(a => "-I" ~ a)(dirs), ", ") ~ fileName;
}
