module unit_threaded.runner;

import unit_threaded.factory;
import unit_threaded.testsuite;
import unit_threaded.term;
import unit_threaded.options;

import std.stdio;
import std.traits;


/**
 * Runs all tests in passed-in modules. Modules are symbols
 */
bool runTests(MODULES...)(in Options options) if(!is(typeof(MODULES[0]) == string)) {

    auto suite = TestSuite(createTests!MODULES(options.tests));
    immutable elapsed = suite.run(options.multiThreaded);

    writefln("\nTime taken: %.3f seconds", elapsed);
    writeln(suite.numTestsRun, " test(s) run, ",
            suite.numFailures, " failed.\n");

    if(!suite.passed) {
        writelnRed("Unit tests failed!\n\n");
        return false; //oops
    }

    writelnGreen("OK!\n\n");
    return true;
}

/**
 * Runs all tests in passed-in modules. Modules are strings
 */
bool runTests(MODULES...)(in Options options) if(is(typeof(MODULES[0]) == string)) {
    mixin(getImportTestsCompileString!MODULES()); //e.g. import foo, bar, baz;
    static immutable runStr = getRunTestsCompileString!MODULES();
    mixin(getRunTestsCompileString!MODULES()); //e.g. runTests!(foo, bar, baz)();
}

private string getImportTestsCompileString(MODULES...)() {
    return "import " ~ getModulesCompileString!MODULES() ~ ";";
}

private string getRunTestsCompileString(MODULES...)() {
    return "return runTests!(" ~ getModulesCompileString!MODULES() ~ ")(options);";
}

private string getModulesCompileString(MODULES...)() {
    import std.array;
    string[] modules;
    foreach(mod; MODULES) modules ~= mod;
    return join(modules, ", ");
}
