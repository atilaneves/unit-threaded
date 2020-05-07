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
    import unit_threaded.runner.runner : runTestsMainHelper;

    mixin runTestsMainHelper!();
}

/**
 * Runs all tests in passed-in modules. Modules can be symbols or
 * strings but they can't mix and match - either all symbols or all
 * strings. It's recommended to use strings since then the modules don't
 * have to be imported first.
 * This wrapper is necessary to allow us to reference an extern-C
 * symbol that would otherwise be mismangled, by importing it as
 * a default parameter.
 */
mixin template runTestsMainHelper(alias rt_moduleDtor = rt_moduleDtor) {
    void main(string[] args) {
        import core.stdc.stdlib : exit;
        import unit_threaded.runner.runner: runTests;

        /* work around https://issues.dlang.org/show_bug.cgi?id=19978 */
        const ret = runTests!Modules(args);
        /* ensure that module destructors run, for instance to write coverage */
        if (ret == 0) rt_moduleDtor;
        exit(ret); /* bypass broken runtime shutdown */
    }
}

extern(C) int rt_moduleDtor() @nogc nothrow @system;

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

    mixin disableDefaultRunner;

    int runTests(string[] args) nothrow {
        import unit_threaded.runner.reflection: allTestData;
        return .runTests(args, allTestData!Modules);
    }

    int runTests(string[] args,
                 in from!"unit_threaded.runner.reflection".TestData[] testData)
        nothrow
    {
        import unit_threaded.runner.reflection: allTestData;
        return .runTests(args, allTestData!Modules);
    }
}


/**
   A template mixin for a static constructor that disables druntimes's
   default test runner so that unit-threaded can take over.
 */
mixin template disableDefaultRunner() {
    shared static this() nothrow {
        import unit_threaded.runner.runner: replaceModuleUnitTester;
        replaceModuleUnitTester;
    }
}


/**
   Generates a main function for collectAndRunTests.
 */
mixin template collectAndRunTestsMain(Modules...) {
    int main(string[] args) {
        import unit_threaded.runner.runner: collectAndRunTests;
        return collectAndRunTests!Modules(args);
    }
}

/**
   Collects test data from each module in Modules and runs tests
   with the supplied command-line arguments.

   Each module in the list must be a string and the respective D
   module must define a module-level function called `testData`
   that returns TestData (obtained by calling allTestData on a list
   of modules to reflect to). This convoluted way of discovering and
   running tests is offered to possibly distribute the compile-time
   price of using reflection to find tests. This is advanced usage.
 */
template collectAndRunTests(Modules...) {

    mixin disableDefaultRunner;

    int collectAndRunTests(string[] args) {

        import unit_threaded.runner.reflection: TestData;

        const(TestData)[] data;

        static foreach(module_; Modules) {
            static assert(is(typeof(module_) == string));
            mixin(`static import `, module_, `;`);
            data ~= mixin(module_, `.testData()`);
        }

        return runTests(args, data);
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
int runTests(string[] args,
             in from!"unit_threaded.runner.reflection".TestData[] testData)
    nothrow
{
    import unit_threaded.runner.options: Options, getOptions;

    Options options;

    try
        options = getOptions(args);
    catch(Exception e) {
        handleException(e);
        return 1;
    }

    return runTests(options, testData);
}

int runTests(in from!"unit_threaded.runner.options".Options options,
             in from!"unit_threaded.runner.reflection".TestData[] testData)
    nothrow
{
    import unit_threaded.runner.testsuite: TestSuite;

    int impl() {
        handleCmdLineOptions(options, testData);
        if (options.exit)
            return 0;

        auto suite = TestSuite(options, testData);
        return suite.run ? 0 : 1;
    }

    try
        return impl;
    catch(Exception e) {
        handleException(e);
        return 1;
    }
}

private void handleException(Exception e) @safe nothrow {
    try {
        import std.stdio: stderr;
        () @trusted { stderr.writeln("Error: ", e.msg); }();
    } catch(Exception oops) {
        import core.stdc.stdio: fprintf, stderr;
        () @trusted { fprintf(stderr, "Error: exception thrown and stderr.writeln failed\n"); }();
    }
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
void replaceModuleUnitTester() nothrow {
    import core.runtime: Runtime;
    try
        Runtime.moduleUnitTester = &moduleUnitTester;
    catch(Exception e) {
        handleException(e);
        import core.stdc.stdio: fprintf, stderr;
        fprintf(stderr, "Error: failed to replace Runtime.moduleUnitTester\n");
        assert(0, "Inconceivable!");
    }
}


/**
 * Replacement for the usual unittest runner. Since unit_threaded
 * runs the tests itself, the moduleUnitTester doesn't really have to do anything.
 */
private bool moduleUnitTester() {
    //this is so unit-threaded's own tests run
    version(testing_unit_threaded) {
        import std.algorithm: startsWith;
        foreach(module_; ModuleInfo) {
            if(module_ && module_.unitTest &&
               module_.name.startsWith("unit_threaded") && // we want to run the "normal" unit tests
               //!module_.name.startsWith("unit_threaded.property") && // left here for fast iteration when developing
               !module_.name.startsWith("unit_threaded.ut.modules")) //but not the ones from the test modules
            {
                import std.stdio: writeln;
                writeln("Running unit-threaded UT for module " ~ module_.name);
                module_.unitTest()();

            }
        }
    }

    return true;
}
