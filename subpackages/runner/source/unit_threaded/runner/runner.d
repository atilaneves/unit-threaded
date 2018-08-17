/**
 * This module implements functions to run the unittests with
 * command-line options.
 */

module unit_threaded.runner.runner;

import unit_threaded.from;

/**
 * Runs all tests in passed-in modules. Modules can be symbols or
 * strings but they can't mix and match - either all symbols or all
 * strings. It's recommended to use strings since then the modules don't
 * have to be imported first.
 * Generates a main function and substitutes the default D
 * runtime unittest runner. This mixin should be used instead of
 * $(D runTests) if a shared library is used instead of an executable.
 */
mixin template runTestsMain(Modules...) if(Modules.length > 0) {
    int main(string[] args) {
        import unit_threaded.runner.runner: runTests;
        return runTests!Modules(args);
    }
}

/**
 * Runs all tests in passed-in modules. Modules can be symbols or
 * strings but they can't mix and match - either all symbols or all
 * strings. It's recommended to use strings since then the modules don't
 * have to be imported first.
 * Arguments are taken from the command-line.
 * -s Can be passed to run in single-threaded mode. The rest
 * of argv is considered to be test names to be run.
 * Params:
 *   args = Arguments passed to main.
 * Returns: An integer suitable for the program's return code.
 */
template runTests(Modules...) if(Modules.length > 0) {

    shared static this() {
        import unit_threaded.runner.runner: replaceModuleUnitTester;
        replaceModuleUnitTester;
    }

    int runTests(string[] args) {
        import unit_threaded.runner.reflection: allTestData;
        return runTests(args, allTestData!Modules);
    }
}



/**
 * Runs all tests in passed-in testData. Arguments are taken from the
 * command-line. `-s` Can be passed to run in single-threaded mode. The
 * rest of argv is considered to be test names to be run.
 * Params:
 *   args = Arguments passed to main.
 *   testData = Data about the tests to run.
 * Returns: An integer suitable for the program's return code.
 */
int runTests(string[] args, in from!"unit_threaded.runner.reflection".TestData[] testData) {
    import unit_threaded.runner.options: getOptions;
    return runTests(getOptions(args), testData);
}

int runTests(in from!"unit_threaded.runner.options".Options options,
             in from!"unit_threaded.runner.reflection".TestData[] testData)
{
    import unit_threaded.runner.testsuite: TestSuite;

    handleCmdLineOptions(options, testData);
    if (options.exit)
        return 0;

    auto suite = TestSuite(options, testData);
    return suite.run ? 0 : 1;
}


private void handleCmdLineOptions(in from!"unit_threaded.runner.options".Options options,
                                  in from!"unit_threaded.runner.reflection".TestData[] testData)
{

    import unit_threaded.runner.io: enableDebugOutput, forceEscCodes;
    import unit_threaded.runner.testcase: enableStackTrace;
    import std.algorithm: map;

    if (options.list) {
        import std.stdio: writeln;

        writeln("Listing tests:");
        foreach (test; testData.map!(a => a.name)) {
            writeln(test);
        }
    }

    if (options.debugOutput)
        enableDebugOutput();

    if (options.forceEscCodes)
        forceEscCodes();

    if (options.stackTraces)
        enableStackTrace();
}


/**
 * Replace the D runtime's normal unittest block tester. If this is not done,
 * the tests will run twice.
 */
void replaceModuleUnitTester() {
    import core.runtime: Runtime;
    Runtime.moduleUnitTester = &moduleUnitTester;
}


/**
 * Replacement for the usual unittest runner. Since unit_threaded
 * runs the tests itself, the moduleUnitTester doesn't really have to do anything.
 */
private bool moduleUnitTester() {
    //this is so unit-threaded's own tests run
    import std.algorithm: startsWith;
    foreach(module_; ModuleInfo) {
        if(module_ && module_.unitTest &&
           module_.name.startsWith("unit_threaded") && // we want to run the "normal" unit tests
           //!module_.name.startsWith("unit_threaded.property") && // left here for fast iteration when developing
           !module_.name.startsWith("unit_threaded.ut.modules")) //but not the ones from the test modules
        {
            version(testing_unit_threaded) {
                import std.stdio: writeln;
                writeln("Running unit-threaded UT for module " ~ module_.name);
            }
            module_.unitTest()();

        }
    }

    return true;
}
