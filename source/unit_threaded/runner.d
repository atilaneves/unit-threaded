module unit_threaded.runner;

import unit_threaded.factory;
import unit_threaded.testsuite;
import unit_threaded.io;
import unit_threaded.options;
import unit_threaded.testcase;

import std.stdio;
import std.traits;
import std.typetuple;
import std.concurrency;
import std.conv;
import std.algorithm;
import core.thread;


/**
 * Runs all tests in passed-in modules. Modules can be symbols
 * or strings. Arguments are taken from the command-line.
 * -s Can be passed to run in single-threaded mode. The rest
 * of argv is considered to be test names to be run.
 * Returns: integer suitable for program return code.
 */
int runTests(MODULES...)(string[] args) {
    const options = getOptions(args);
    if(options.list) {
        writeln("Listing tests:");
        foreach(test; getTestNames!MODULES()) {
            writeln(test);
        }
    }

    if(options.exit) return 0;
    if(options.debugOutput) enableDebugOutput();
    if(options.forceEscCodes) forceEscCodes();

    immutable success = runTests!MODULES(options);
    return success ? 0 : 1;
}

private auto getTestNames(MOD_SYMBOLS...)() if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    return getTestClassesAndFunctions!MOD_SYMBOLS.map!(a => a.name);
}

private auto getTestNames(MOD_STRINGS...)() if(allSatisfy!(isSomeString, typeof(MOD_STRINGS))) {
    mixin(getImportTestsCompileString!MOD_STRINGS()); //e.g. import foo, bar, baz;
    enum mod_symbols = getModulesCompileString!MOD_STRINGS; //e.g. foo, bar, baz
    mixin("return getTestClassesAndFunctions!(" ~ mod_symbols ~ ").map!(a => a.name);");
}

/**
 * Runs all tests in passed-in modules. Modules are symbols.
 */
bool runTests(MOD_SYMBOLS...)(in Options options) if(!anySatisfy!(isSomeString, typeof(MOD_SYMBOLS))) {
    WriterThread.get(); //make sure this is up
    //sleep to give WriterThread some time to set up. Otherwise,
    //tests with output could write to stdout in the meanwhile
    Thread.sleep(dur!"msecs"(5));

    auto tests = createTests!MOD_SYMBOLS(options.tests);
    if(!tests) {
        utWritelnRed("Error! No tests to run for args: ");
        utWriteln(options.tests);
        return false;
    }

    auto suite = TestSuite(tests);
    immutable elapsed = suite.run(options.multiThreaded);

    if(!suite.numTestsRun) {
        writeln("Did not run any tests!!!");
        return false;
    }

    utWriteln("\nTime taken: ", elapsed, " seconds");
    utWrite(suite.numTestsRun, " test(s) run, ");
    const failuresStr = text(suite.numFailures, " failed");
    if(suite.numFailures) {
        utWriteRed(failuresStr);
    } else {
        utWrite(failuresStr);
    }
    const numHidden = getTestClassesAndFunctions!MOD_SYMBOLS.filter!(a => a.hidden).count;
    if(numHidden) {
        utWrite(", ");
        utWriteYellow(numHidden, " hidden");
    }
    utWriteln(".\n");

    if(!suite.passed) {
        utWritelnRed("Unit tests failed!\n");
        return false; //oops
    }

    utWritelnGreen("OK!\n");

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
    return modules.join(", ");
}
