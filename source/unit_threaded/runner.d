module unit_threaded.runner;

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
    handleCmdLineOptions(options, testData);
    if(options.exit) return 0;

    auto suite = TestSuite(options, testData);
    immutable success = suite.run;
    return success ? 0 : 1;
}


private void handleCmdLineOptions(in Options options, in TestData[] testData)
{
    if(options.list)
    {
        import std.stdio;

        writeln("Listing tests:");
        foreach(test; testData.map!(a => a.name))
        {
            writeln(test);
        }
    }

    if(options.debugOutput) enableDebugOutput();
    if(options.forceEscCodes) forceEscCodes();
}
