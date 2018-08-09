/**
   A module for static constructors to avoid cyclic dependencies.
 */
module unit_threaded.static_;

version(unitThreadedLight) {

    shared static this() {
        import std.algorithm: canFind;
        import std.parallelism: parallel;
        import core.runtime: Runtime;

        Runtime.moduleUnitTester = () {

            // ModuleInfo has opApply, can't use parallel on that so we collect
            // all the modules with unit tests first
            ModuleInfo*[] modules;
            foreach(module_; ModuleInfo) {
                if(module_ && module_.unitTest)
                    modules ~= module_;
            }

            version(unitUnthreaded)
                enum singleThreaded = true;
            else
                const singleThreaded = Runtime.args.canFind("-s") || Runtime.args.canFind("--single");

            if(singleThreaded)
                foreach(module_; modules)
                    module_.unitTest()();
             else
                foreach(module_; modules.parallel)
                    module_.unitTest()();

            return true;
        };
    }
}

static this() {
    import unit_threaded.io: _useEscCodes, shouldUseEscCodes;
    version (Posix) {
        import std.stdio: stdout;
        import core.sys.posix.unistd: isatty;
        _useEscCodes = shouldUseEscCodes;
    }
}
