#!/usr/bin/rdmd

module unit_threaded.finder;


import std.stdio;
import std.file;
import std.exception;
import std.array;
import std.algorithm;
import std.path;

void main(string[] args) {
    const dirs = args[1..$];
    writeln("Finding all test cases in ", dirs);
    writeln(findModuleNames(dirs));
}


auto findModuleEntries(in string[] dirs) {
    DirEntry[] modules;
    foreach(dir; dirs) {
        enforce(isDir(dir), "All arguments must be directory names");
        modules ~= array(dirEntries(dir, "*.d", SpanMode.depth));
    }
    return modules;
}

auto findModuleNames(in string[] dirs) {
    //cut off extension
    return map!(a => replace(a.name[0 .. $-2], dirSeparator, "."))(findModuleEntries(dirs));
}
