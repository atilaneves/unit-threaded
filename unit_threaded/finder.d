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


/**
 * args is a filename and a list of directories to search in
 * the filename is the 1st element, the others are directories.
 */
int main(string[] args) {
    const fileName = args[1];
    const dirs = args[2..$];
    writeln("Finding all test cases in ", dirs);

    auto modules = findModuleNames(dirs);
    auto file = writeFile(fileName, modules, dirs);
    printFile(file);

    auto rdmdArgs = getRdmdArgs(fileName, dirs);
    writeln("Executing rdmd like this: ", join(rdmdArgs, ", "));
    auto rdmd = execute(rdmdArgs);

    writeln(rdmd.output);
    return rdmd.status;
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

private auto writeFile(in string fileName, string[] modules, in string[] dirs) {
    auto file = File(fileName, "w");
    file.writeln("import unit_threaded.runner;");
    file.writeln("import std.stdio;");
    file.writeln("");
    file.writeln("int main(string[] args) {");
    file.writeln(`    writeln("\nAutomatically generated file");`);
    file.writeln("    writeln(`Running unit tests from dirs " ~ to!string(dirs) ~ "\n`);");
    file.writeln("    return runTests!(" ~ join(map!(a => `"` ~ a ~ `"`)(modules), ", ") ~ ")(args);");
    file.writeln("}");
    file.close();

    return File(fileName, "r");
}

private void printFile(File file) {
    writeln("Executing this code:\n");
    foreach(line; file.byLine()) {
        writeln(line);
    }
    writeln();
    file.rewind();
}

private auto getRdmdArgs(in string fileName, in string[] dirs) {
    return [ "rdmd" ] ~ join(map!(a => "-I" ~ a)(dirs), ", ") ~ fileName;
}
