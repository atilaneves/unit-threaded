module unit_threaded.dub;

import unit_threaded.runtime;
import std.json;
import std.algorithm;
import std.array;
import std.process;
import std.exception;
import std.conv;
import std.stdio;


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

private string[] jsonValueToFiles(JSONValue files) @trusted {
    import std.array;

    return files.array.
        filter!(a => ("type" in a && a.byKey("type").str == "source") ||
                     ("role" in a && a.byKey("role").str == "source") ||
                     ("type" !in a && "role" !in a)).
        map!(a => a.byKey("path").str).
        array;
}

private string[] jsonValueToStrings(JSONValue json) @trusted {
    return json.array.map!(a => a.str).array;
}


private auto byKey(JSONValue json, in string key) @trusted {
    return json.object[key];
}

private auto byOptionalKey(JSONValue json, in string key, bool def) {
    import std.conv: to;
    auto value = json.object;
    return key in value ? value[key].boolean : def;
}

//std.json has no conversion to bool
private bool boolean(JSONValue json) @trusted {
    import std.exception: enforce;
    enforce!JSONException(json.type == JSON_TYPE.TRUE || json.type == JSON_TYPE.FALSE,
                          "JSONValue is not a boolean");
    return json.type == JSON_TYPE.TRUE;
}

private string getOptional(JSONValue json, in string key) @trusted {
    auto aa = json.object;
    return key in aa ? aa[key].str : "";
}

private string[] getOptionalList(JSONValue json, in string key) @trusted {
    auto aa = json.object;
    return key in aa ? aa[key].jsonValueToStrings : [];
}


DubInfo getDubInfo(in bool verbose) {
    import core.exception;

    if(verbose)
        writeln("Running dub describe");

    immutable args = ["dub", "describe", "-c", "unittest"];
    immutable res = execute(args);
    enforce(res.status == 0, text("Could not execute ", args.join(" "), ":\n", res.output));
    try {
        return getDubInfo(res.output.find("{"));
    } catch(RangeError e) {
        throw new Exception(text("Could not parse the output of dub describe:\n", res.output, "\n", e.toString));
    }
}

bool isDubProject() {
    import std.file;
    return "dub.sdl".exists || "dub.json".exists || "package.json".exists;
}


// set import paths from dub information
void dubify(ref Options options) {
    if(!isDubProject) return;

    auto dubInfo = getDubInfo(options.verbose);
    options.includes = dubInfo.packages.
        map!(a => a.importPaths.map!(b => buildPath(a.path, b)).array).
        reduce!((a, b) => a ~ b).array;
    options.files = dubInfo.packages[0].files;
}
