/**
   The different TestCase classes
 */
module unit_threaded.testcase;


private shared(bool) _stacktrace = false;

private void setStackTrace(bool value) @trusted nothrow @nogc {
    synchronized {
        _stacktrace = value;
    }
}

/// Let AssertError(s) propagate and thus dump a stacktrace.
public void enableStackTrace() @safe nothrow @nogc {
    setStackTrace(true);
}

/// (Default behavior) Catch AssertError(s) and thus allow all tests to be ran.
public void disableStackTrace() @safe nothrow @nogc {
    setStackTrace(false);
}

/**
 * Class from which other test cases derive
 */
class TestCase {

    import unit_threaded.io: Output;

    /**
     * Returns: the name of the test
     */
    string getPath() const pure nothrow {
        return this.classinfo.name;
    }

    /**
     * Executes the test.
     * Returns: array of failures (child classes may have more than 1)
     */
    string[] opCall() {
        static if(__VERSION__ >= 2077)
            import std.datetime.stopwatch: StopWatch, AutoStart;
        else
            import std.datetime: StopWatch, AutoStart;

        currentTest = this;
        auto sw = StopWatch(AutoStart.yes);
        doTest();
        flushOutput();
        return _failed ? [getPath()] : [];
    }

    /**
     Certain child classes override this
     */
    ulong numTestsRun() const { return 1; }
    void showChrono() @safe pure nothrow { _showChrono = true; }
    void setOutput(Output output) @safe pure nothrow { _output = output; }

package:

    static TestCase currentTest;
    Output _output;

    void silence() @safe pure nothrow { _silent = true; }

    final Output getWriter() @safe {
        import unit_threaded.io: WriterThread;
        return _output is null ? WriterThread.get : _output;
    }

protected:

    abstract void test();
    void setup() { } ///override to run before test()
    void shutdown() { } ///override to run after test()

private:

    bool _failed;
    bool _silent;
    bool _showChrono;

    final auto doTest() {
        import std.conv: text;
        import std.datetime: Duration;
        static if(__VERSION__ >= 2077)
            import std.datetime.stopwatch: StopWatch, AutoStart;
        else
            import std.datetime: StopWatch, AutoStart;

        auto sw = StopWatch(AutoStart.yes);
        print(getPath() ~ ":\n");
        check(setup());
        check(test());
        check(shutdown());
        if(_failed) print("\n");
        if(_showChrono) print(text("    (", cast(Duration)sw.peek, ")\n\n"));
        if(_failed) print("\n");
    }

    final bool check(E)(lazy E expression) {
        import unit_threaded.should: UnitTestException;
        try {
            expression();
        } catch(UnitTestException ex) {
            fail(ex.toString());
        } catch(Throwable ex) {
            fail("\n    " ~ ex.toString() ~ "\n");
        }

        return !_failed;
    }

    final void fail(in string msg) {
        _failed = true;
        print(msg);
    }

    final void print(in string msg) {
        import unit_threaded.io: write;
        if(!_silent) getWriter.write(msg);
    }

    final void flushOutput() {
        getWriter.flush;
    }
}

/**
   A test that runs other tests.
 */
class CompositeTestCase: TestCase {
    void add(TestCase t) { _tests ~= t;}

    void opOpAssign(string op : "~")(TestCase t) {
        add(t);
    }

    override string[] opCall() {
        import std.algorithm: map, reduce;
        return _tests.map!(a => a()).reduce!((a, b) => a ~ b);
    }

    override void test() { assert(false, "CompositeTestCase.test should never be called"); }

    override ulong numTestsRun() const {
        return _tests.length;
    }

    package TestCase[] tests() @safe pure nothrow {
        return _tests;
    }

    override void showChrono() {
        foreach(test; _tests) test.showChrono;
    }

private:

    TestCase[] _tests;
}

/**
   A test that should fail
 */
class ShouldFailTestCase: TestCase {
    this(TestCase testCase, in TypeInfo exceptionTypeInfo) {
        this.testCase = testCase;
        this.exceptionTypeInfo = exceptionTypeInfo;
    }

    override string getPath() const pure nothrow {
        return this.testCase.getPath;
    }

    override void test() {
        import unit_threaded.should: UnitTestException;
        import std.exception: enforce, collectException;
        import std.conv: text;

        const ex = collectException!Throwable(testCase.test());
        enforce!UnitTestException(ex !is null, "Test '" ~ testCase.getPath ~ "' was expected to fail but did not");
        enforce!UnitTestException(exceptionTypeInfo is null || typeid(ex) == exceptionTypeInfo,
                                  text("Test '", testCase.getPath, "' was expected to throw ",
                                       exceptionTypeInfo, " but threw ", typeid(ex)));
    }

private:

    TestCase testCase;
    const(TypeInfo) exceptionTypeInfo;
}

/**
   A test that is a regular function.
 */
class FunctionTestCase: TestCase {

    import unit_threaded.reflection: TestData, TestFunction;

    this(in TestData data) pure nothrow {
        _name = data.getPath;
        _func = data.testFunction;
    }

    override void test() {
        _func();
    }

    override string getPath() const pure nothrow {
        return _name;
    }

    private string _name;
    private TestFunction _func;
}

/**
   A test that is a `unittest` block.
 */
class BuiltinTestCase: FunctionTestCase {

    import unit_threaded.reflection: TestData;

    this(in TestData data) pure nothrow {
        super(data);
    }

    override void test() {
        import core.exception: AssertError;

        try
            super.test();
        catch(AssertError e) {
            import unit_threaded.should: fail;
             fail(_stacktrace? e.toString() : e.msg, e.file, e.line);
        }
    }
}


/**
   A test that is expected to fail some of the time.
 */
class FlakyTestCase: TestCase {
    this(TestCase testCase, int retries) {
        this.testCase = testCase;
        this.retries = retries;
    }

    override string getPath() const pure nothrow {
        return this.testCase.getPath;
    }

    override void test() {

        foreach(i; 0 .. retries) {
            try {
                testCase.test;
                break;
            } catch(Throwable t) {
                if(i == retries - 1)
                    throw t;
            }
        }
    }

private:

    TestCase testCase;
    int retries;
}
