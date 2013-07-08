module ut.list;

import std.traits;

string[] getTestClassNames(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes = [];
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            classes ~= fullyQualifiedName!mod ~ "." ~ klass;
        }
    }

    return classes;
}
