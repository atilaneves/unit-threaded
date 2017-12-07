module unit_threaded.from;

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
