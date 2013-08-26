module unit_threaded.runner;

import unit_threaded.factory;
import unit_threaded.testsuite;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.testcase;
import unit_threaded.writer_thread;

import std.stdio;
import std.traits;
import std.typetuple;
import std.concurrency;
import std.conv;
import core.thread;


/**
 * Runs all tests in passed-in modules. Modules can be symbols
 * or strings. Arguments are taken from the command-line.
 * -s Can be passed to run in single-threaded mode. The rest
 * of argv is considered to be test names to be run.
 * Returns: integer suitable for program return code.
 */
int runTests(MODULES...)(string[] args) {
    immutable options = getOptions(args);
    if(options.debugOutput) enableDebugOutput();

    immutable success = runTests!MODULES(options);
    return success ? 0 : 1;
}


/**
 * Runs all tests in passed-in modules. Modules are symbols.
 */
bool runTests(MOD_SYMBOLS...)(in Options options) if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    WriterThread.get(); //make sure this is up
    //sleep to give WriterThread some time to set up. Otherwise,
    //tests with output could write to stdout in the meanwhile
    Thread.sleep(dur!"msecs"(5));

    auto suite = TestSuite(createTests!MOD_SYMBOLS(options.tests));
    immutable elapsed = suite.run(options.multiThreaded);

    if(!suite.numTestsRun) {
        writeln("Did not run any tests!!!");
        return false;
    }

    WriterThread.get().writeln("\nTime taken: ", elapsed, " seconds");
    WriterThread.get().writeln(suite.numTestsRun, " test(s) run, ",
                               suite.numFailures, " failed.\n");

    if(!suite.passed) {
        WriterThread.get().writeln(red("Unit tests failed!\n"));
        return false; //oops
    }

    WriterThread.get().writeln(green("OK!\n"));

    return true;
}

/**
 * Runs all tests in passed-in modules. Modules are strings.
 */
bool runTests(MOD_STRINGS...)(in Options options) if(allSatisfy!(isSomeString, typeof(MOD_STRINGS))) {
    mixin(getImportTestsCompileString!MOD_STRINGS()); //e.g. import foo, bar, baz;
    static immutable runStr = getRunTestsCompileString!MOD_STRINGS();
    mixin(getRunTestsCompileString!MOD_STRINGS()); //e.g. runTests!(foo, bar, baz)();
}

private string getImportTestsCompileString(MOD_STRINGS...)() {
    return "import " ~ getModulesCompileString!MOD_STRINGS() ~ ";";
}

private string getRunTestsCompileString(MOD_STRINGS...)() {
    return "return runTests!(" ~ getModulesCompileString!MOD_STRINGS() ~ ")(options);";
}

private string getModulesCompileString(MOD_STRINGS...)() {
    import std.array;
    string[] modules;
    foreach(mod; MOD_STRINGS) modules ~= mod;
    return join(modules, ", ");
}
