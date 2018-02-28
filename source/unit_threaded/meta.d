/**
   Meta-programming helper functions.
 */
module unit_threaded.meta;


/// Import moduleMember from module_
string importMember(alias module_)(string moduleMember) {
    import std.traits: fullyQualifiedName;
    return "import " ~ fullyQualifiedName!module_ ~ `: ` ~ moduleMember ~ ";";
}
