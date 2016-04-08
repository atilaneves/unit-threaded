module unit_threaded.meta;

import std.traits;


string importMember(alias module_)(string moduleMember) {
    return "import " ~ fullyQualifiedName!module_ ~ `: ` ~ moduleMember ~ ";";
}
