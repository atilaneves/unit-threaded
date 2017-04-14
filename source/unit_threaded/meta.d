module unit_threaded.meta;



string importMember(alias module_)(string moduleMember) {
    import std.traits: fullyQualifiedName;
    return "import " ~ fullyQualifiedName!module_ ~ `: ` ~ moduleMember ~ ";";
}
