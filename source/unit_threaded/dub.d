/**
   Code to parse the output from `dub describe` and generate the main
   test file automatically.
 */
module unit_threaded.dub;

import unit_threaded.from;


struct DubPackage {
    string name;
    string path;
    string mainSourceFile;
    string targetFileName;
    string[] flags;
    string[] importPaths;
    string[] stringImportPaths;
    string[] files;
    string targetType;
    string[] versions;
    string[] dependencies;
    string[] libs;
    bool active;
}

struct DubInfo {
    DubPackage[] packages;
}

DubInfo getDubInfo(string jsonString) @trusted {
    import std.json: parseJSON;
    import std.algorithm: map, filter;
    import std.array: array;

    auto json = parseJSON(jsonString);
    auto packages = json.byKey("packages").array;
    return DubInfo(packages.
                   map!(a => DubPackage(a.byKey("name").str,
                                        a.byKey("path").str,
                                        a.getOptional("mainSourceFile"),
                                        a.getOptional("targetFileName"),
                                        a.byKey("dflags").jsonValueToStrings,
                                        a.byKey("importPaths").jsonValueToStrings,
                                        a.byKey("stringImportPaths").jsonValueToStrings,
                                        a.byKey("files").jsonValueToFiles,
                                        a.getOptional("targetType"),
                                        a.getOptionalList("versions"),
                                        a.getOptionalList("dependencies"),
                                        a.getOptionalList("libs"),
                                        a.byOptionalKey("active", true), //true for backwards compatibility
                            )).
                   filter!(a => a.active).
                   array);
}

private string[] jsonValueToFiles(from!"std.json".JSONValue files) @trusted {
    import std.algorithm: map, filter;
    import std.array: array;

    return files.array.
        filter!(a => ("type" in a && a.byKey("type").str == "source") ||
                     ("role" in a && a.byKey("role").str == "source") ||
                     ("type" !in a && "role" !in a)).
        map!(a => a.byKey("path").str).
        array;
}

private string[] jsonValueToStrings(from!"std.json".JSONValue json) @trusted {
    import std.algorithm: map, filter;
    import std.array: array;

    return json.array.map!(a => a.str).array;
}


private auto byKey(from!"std.json".JSONValue json, in string key) @trusted {
    import std.json: JSONException;
    if (auto p = key in json.object)
        return *p;
    else throw new JSONException("\"" ~ key ~ "\" not found");
}

private auto byOptionalKey(from!"std.json".JSONValue json, in string key, bool def) {
    if (auto p = key in json.object)
        return (*p).boolean;
    else
        return def;
}

//std.json has no conversion to bool
private bool boolean(from!"std.json".JSONValue json) @trusted {
    import std.exception: enforce;
    import std.json: JSONException, JSON_TYPE;
    enforce!JSONException(json.type == JSON_TYPE.TRUE || json.type == JSON_TYPE.FALSE,
                          "JSONValue is not a boolean");
    return json.type == JSON_TYPE.TRUE;
}

private string getOptional(from!"std.json".JSONValue json, in string key) @trusted {
    if (auto p = key in json.object)
        return p.str;
    else
        return "";
}

private string[] getOptionalList(from!"std.json".JSONValue json, in string key) @trusted {
    if (auto p = key in json.object)
        return (*p).jsonValueToStrings;
    else
        return [];
}


DubInfo getDubInfo(in bool verbose) {
    import std.json: JSONException;
    import std.conv: text;
    import std.algorithm: joiner, map, copy;
    import std.stdio: writeln;
    import std.exception: enforce;
    import std.process: pipeProcess, Redirect, wait;
    import std.array: join, appender;

    if(verbose)
        writeln("Running dub describe");

    immutable args = ["dub", "describe", "-c", "unittest"];
    auto pipes = pipeProcess(args, Redirect.stdout | Redirect.stderr);
    scope(exit) wait(pipes.pid); // avoid zombies in all cases
    string stdoutStr;
    string stderrStr;
    enum chunkSize = 4096;
    pipes.stdout.byChunk(chunkSize).joiner
        .map!"cast(immutable char)a".copy(appender(&stdoutStr));
    pipes.stderr.byChunk(chunkSize).joiner
        .map!"cast(immutable char)a".copy(appender(&stderrStr));
    auto status = wait(pipes.pid);
    auto allOutput = "stdout:\n" ~ stdoutStr ~ "\nstderr:\n" ~ stderrStr;

    enforce(status == 0, text("Could not execute ", args.join(" "),
                ":\n", allOutput));
    try {
        return getDubInfo(stdoutStr);
    } catch(JSONException e) {
        throw new Exception(text("Could not parse the output of dub describe:\n", allOutput, "\n", e.toString));
    }
}

bool isDubProject() {
    import std.file;
    return "dub.sdl".exists || "dub.json".exists || "package.json".exists;
}


// set import paths from dub information
void dubify(ref from!"unit_threaded.runtime".Options options) {

    import std.path: buildPath;
    import std.algorithm: map, reduce;
    import std.array: array;

    if(!isDubProject) return;

    auto dubInfo = getDubInfo(options.verbose);
    options.includes = dubInfo.packages.
        map!(a => a.importPaths.map!(b => buildPath(a.path, b)).array).
        reduce!((a, b) => a ~ b).array;
    options.files = dubInfo.packages[0].files;
}
