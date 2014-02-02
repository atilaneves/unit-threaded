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
    const options = getOptions(args);
    if(options.help) return 0;

    writeFile(options, findModuleNames(options.dirs));
    if(options.fileNameSpecified) {
        auto rdmdArgs = getRdmdArgs(options);
        writeRdmdArgsOutString(rdmdArgs);
        return 0;
    }
    immutable rdmd = executeRdmd(options);
    writeln(rdmd.output);

    return rdmd.status;
}

private struct Options {
    //dtest options
    bool verbose;
    bool fileNameSpecified;
    string fileName;
    string[] dirs;
    string[] includes;
    string unit_threaded;
    bool help;

    //unit_threaded.runner options
    string[] args;
    bool debugOutput;
    bool single;
    bool list;
    string[] getRunnerArgs() const {
        auto args = ["--esccodes"];
        if(single) args ~= "--single";
        if(debugOutput) args ~= "--debug";
        if(list) args ~= "--list";
        return args;
    }
}

private Options getOptions(string[] args) {
    Options options;
    getopt(args,
           //dtest options
           "verbose|v", &options.verbose,
           "file|f", &options.fileName,
           "unit_threaded|u", &options.unit_threaded,
           "help|h", &options.help,
           "test|t", &options.dirs,
           "I", &options.includes,
           //these are unit_threaded options
           "single|s", &options.single, //single-threaded
           "debug|d", &options.debugOutput, //print debug output
           "list|l", &options.list
        );

    if(options.help) {
        printHelp();
        return options;
    }

    if(!options.unit_threaded) {
        writeln("Path to unit_threaded library not specified with -u, might fail");
    }

    if(options.fileName) {
        options.fileNameSpecified = true;
    } else {
        options.fileName = createFileName(); //random filename
    }
    if(!options.dirs) options.dirs = ["tests"];
    options.args = args[1..$];
    if(options.verbose) writeln(__FILE__, ": finding all test cases in ", options.dirs);
    return options;
}

private void printHelp() {
        writeln(q"EOS

Usage: dtest [options] [test1] [test2]...

    Options:
        -h/--help: help
        -t/--test: add a test directory to the list. If no test directories
        are specified, then the default list is ["tests"]
        -u/--unit_threaded: directory location of the unit_threaded library
        -I: extra include directories to specify to rdmd
        -d/--debug: print debug information
        -f/--file: file name to write to
        -s/--single: run the tests in one thread
        -d/--debug: print debugging information from the tests
        -l/--list: list all tests but do not run them

    This will run all unit tests encountered in the given directories
    (see -t option). It does this by scanning them and writing a D source
    file that imports all of them then running that source file with rdmd.
    By default the source file is a randomly named temporary file but that
    can be changed with the -f option. If the unit_threaded library is not
    in the default search paths then it must be specified with the -u option.
    If any command-line arguments exist they will be forwarded to the
    unit_threaded library and used as the names of the tests to run. If
    none are specified, all of them are run.

    To run all tests located in a directory called "tests":

    dtest -u<PATH_TO_UNIT_THREADED>

    To run all tests in dir1, dir2, etc.:

    dtest -u<PATH_TO_UNIT_THREADED> -t dir1 -t dir2...

    To run tests foo and bar in directory mydir:

    dtest -u<PATH_TO_UNIT_THREADED> -t mydir mydir.foo mydir.bar

EOS");
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
    }
    return modules;
}

auto findModuleNames(in string[] dirs) {
    //cut off extension
    return array(map!(a => replace(a.name[0 .. $-2], dirSeparator, "."))(findModuleEntries(dirs)));
}

private auto writeFile(in Options options, in string[] modules) {
    auto wfile = File(options.fileName, "w");
    wfile.writeln("import unit_threaded.runner;");
    wfile.writeln("import std.stdio;");
    wfile.writeln("");
    wfile.writeln("int main(string[] args) {");
    wfile.writeln(`    writeln("\nAutomatically generated file ` ~ options.fileName ~ `");`);
    wfile.writeln("    writeln(`Running unit tests from dirs " ~ to!string(options.dirs) ~ "\n`);");
    wfile.writeln("    return runTests!(" ~ join(map!(a => `"` ~ a ~ `"`)(modules), ", ") ~ ")(args);");
    wfile.writeln("}");
    wfile.close();

    auto rfile = File(options.fileName, "r");
    printFile(options, rfile);
    return rfile;
}

private void printFile(in Options options, File file) {
    if(!options.verbose) return;
    writeln("Executing this code:\n");
    foreach(line; file.byLine()) {
        writeln(line);
    }
    writeln();
    file.rewind();
}

private auto getRdmdArgs(in Options options) {
    const testIncludeDirs = options.dirs ~ options.unit_threaded ? [options.unit_threaded] : [];
    const testIncludes = array(map!(a => "-I" ~ a)(testIncludeDirs));
    const moreIncludes = array(map!(a => "-I" ~ a)(options.includes));
    const includes = testIncludes ~ moreIncludes;
    return [ "rdmd" ] ~ includes ~ options.fileName ~ options.getRunnerArgs() ~ options.args;
}

private auto writeRdmdArgsOutString(string[] args) {
    return writeln("Execute unit test binary with: ", join(args, " "));
}

private auto executeRdmd(in Options options) {
    auto rdmdArgs = getRdmdArgs(options);
    if(options.verbose) writeRdmdArgsOutString(rdmdArgs);
    return execute(rdmdArgs);
}
