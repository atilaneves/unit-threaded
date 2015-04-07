module unit_threaded.runner;

import unit_threaded.factory;
import unit_threaded.testsuite;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.testcase;
import unit_threaded.reflection: allTestData;

import std.conv: text;
import std.algorithm: map, filter, count;


/**
 * Runs all tests in passed-in modules. Modules can be symbols
 * or strings. Arguments are taken from the command-line.
 * -s Can be passed to run in single-threaded mode. The rest
 * of argv is considered to be test names to be run.
 * Returns: integer suitable for program return code.
 */
int runTests(MODULES...)(string[] args)
{
    return runTests(args, allTestData!MODULES);
}

/**
 * Runs all tests in passed-in testData. Arguments are taken from the
 * command-line.  -s Can be passed to run in single-threaded mode. The
 * rest of argv is considered to be test names to be run.  Returns:
 * integer suitable for program return code.
 */
int runTests(string[] args, in TestData[] testData)
{
    const options = getOptions(args);

    if(options.list)
    {
        import std.stdio;

        writeln("Listing tests:");
        foreach(test; testData.map!(a => a.name))
        {
            writeln(test);
        }
    }

    if(options.exit) return 0;
    if(options.debugOutput) enableDebugOutput();
    if(options.forceEscCodes) forceEscCodes();

    immutable success = runTests(options, testData);
    return success ? 0 : 1;
}

/**
 * Runs all tests in passed-in testData. with the given options.
 * Returns: true on success, false if any of the tests failed.
 */
bool runTests(in Options options, in TestData[] testData)
{
    WriterThread.start;
    scope(exit) WriterThread.get.join;

    auto testCases = createTestCases(testData, options.testsToRun);
    if(!testCases)
    {
        utWritelnRed("Error! No tests to run for args: ");
        utWriteln(options.testsToRun);
        return false;
    }

    auto suite = TestSuite(testCases);
    immutable elapsed = suite.run(options);

    if(!suite.numTestsRun)
    {
        utWriteln("Did not run any tests!!!");
        return false;
    }

    utWriteln("\nTime taken: ", elapsed);
    utWrite(suite.numTestsRun, " test(s) run, ");
    const failuresStr = text(suite.numFailures, " failed");
    if(suite.numFailures)
    {
        utWriteRed(failuresStr);
    }
    else
    {
        utWrite(failuresStr);
    }

    void printAbout(string attr)(in string msg)
    {
        const num = testData.filter!(a => mixin("a. " ~ attr)).count;
        if(num)
        {
            utWrite(", ");
            utWriteYellow(num, " " ~ msg);
        }
    }

    printAbout!"hidden"("hidden");
    printAbout!"shouldFail"("failing as expected");

    utWriteln(".\n");

    if(!suite.passed)
    {
        utWritelnRed("Unit tests failed!\n");
        return false; //oops
    }

    utWritelnGreen("OK!\n");

    return true;
}
