/**
   A module for static constructors to avoid cyclic dependencies.
 */
module unit_threaded.runner.static_;

static this() {
    import unit_threaded.runner.io: _useEscCodes, shouldUseEscCodes;
    version (Posix) {
        import std.stdio: stdout;
        import core.sys.posix.unistd: isatty;
        _useEscCodes = shouldUseEscCodes;
    }
}
