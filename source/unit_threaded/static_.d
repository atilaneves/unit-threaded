/**
   A module for static constructors to avoid cyclic dependencies.
 */
module unit_threaded.static_;

version(unitThreadedLight) {

    shared static this() {
        import std.algorithm: canFind, startsWith;
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

            void runModuleTests(ModuleInfo* module_) {
                version(testing_unit_threaded) {
                    const shouldTest =
                    module_.name.startsWith("unit_threaded.ut") &&
                    !module_.name.startsWith("unit_threaded.ut.modules");
                } else
                      enum shouldTest = true;

                if(shouldTest)
                    module_.unitTest()();
            }

            if(singleThreaded)
                foreach(module_; modules)
                    runModuleTests(module_);
             else
                foreach(module_; modules.parallel)
                    runModuleTests(module_);

            return true;
        };
    }
}
