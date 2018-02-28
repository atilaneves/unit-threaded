/**
   Eliminate top-level imports.
 */
module unit_threaded.from;

/**
   Local imports everywhere.
 */
template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
