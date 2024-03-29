module unit_threaded.autorunner;

// a no-op when compiling without '-unittest'
version (unittest):

static if (!__traits(compiles, () { import dub_test_root; })) {
    static assert(false, "Couldn't import 'dub_test_root' auto-generated by dub. " ~
        "The 'unittest' dub configuration must NOT have an 'executable' target type.");
} else:

// import an AliasSeq of all modules of the root project being tested
import dub_test_root : allModules;

// replace the runtime's unit-tester
shared static this() {
    import core.runtime : Runtime, UnitTestResult;
    import std.algorithm : filter, startsWith;
    import std.array : array;
    import unit_threaded.runner.runner : runTests;
    import unit_threaded.runner.reflection : allTestData;

    Runtime.extendedModuleUnitTester = function() {
        // The --DRT-* (druntime) options are filtered out automatically for D main().
        // Replicate that to allow using them for the test runner executable.
        auto args = Runtime.args.filter!(a => !a.startsWith("--DRT-")).array;

        const r = runTests(args, allTestData!allModules);

        const numExecuted = 1;
        const numPassed = (r == 0) ? 1 : 0; // determines process exit code
        const runMain = false;
        const printSummary = false;
        return UnitTestResult(numExecuted, numPassed, runMain, printSummary);
    };
}
