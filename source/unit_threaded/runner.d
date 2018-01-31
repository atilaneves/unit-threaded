/**
 * This module implements functions to run the unittests with
 * command-line options.
 */

module unit_threaded.runner;

import unit_threaded.from;

/**
 * Runs all tests in passed-in modules. Modules can be symbols or
 * strings. Generates a main function and substitutes the default D
 * runtime unittest runner. This mixin should be used instead of
 * $(D runTests) if a shared library is used instead of an executable.
 */
mixin template runTestsMixin(Modules...) if(Modules.length > 0) {

    shared static this() {
        import unit_threaded.testsuite : replaceModuleUnitTester;

        replaceModuleUnitTester;
    }

    int main(string[] args) {
        return runTests!Modules(args);
    }
}

/**
 * Runs all tests in passed-in modules. Modules can be symbols
 * or strings. Arguments are taken from the command-line.
 * -s Can be passed to run in single-threaded mode. The rest
 * of argv is considered to be test names to be run.
 * Params:
 *   args = Arguments passed to main.
 * Returns: An integer suitable for the program's return code.
 */
int runTests(Modules...)(string[] args) if(Modules.length > 0) {
    import unit_threaded.reflection: allTestData;
    return runTests(args, allTestData!Modules);
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
int runTests(string[] args, in from!"unit_threaded.reflection".TestData[] testData) {
    import unit_threaded.options: getOptions;
    return runTests(getOptions(args), testData);
}

int runTests(in from!"unit_threaded.options".Options options,
             in from!"unit_threaded.reflection".TestData[] testData)
{
    import unit_threaded.testsuite: TestSuite;

    handleCmdLineOptions(options, testData);
    if (options.exit)
        return 0;

    auto suite = TestSuite(options, testData);
    return suite.run ? 0 : 1;
}


private void handleCmdLineOptions(in from!"unit_threaded.options".Options options,
                                  in from!"unit_threaded.reflection".TestData[] testData)
{

    import unit_threaded.io: enableDebugOutput, forceEscCodes;
    import unit_threaded.testcase: enableStackTrace;
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
