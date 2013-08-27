module example.tests.pass_tests;

import unit_threaded.all;
import core.thread;


class IntEqualTest: TestCase {
    override void test() {
        checkNotEqual(1, 5);
        checkNotEqual(5, 1);
        checkEqual(3, 3);
        checkEqual(2, 2);
    }
}

class DoubleEqualTest: TestCase {
    override void test() {
        checkNotEqual(1.0, 2.0);
        checkEqual(2.0, 2.0);
        checkEqual(2.0, 2.0);
    }
}

void testEqual() {
    checkEqual(1, 1);
    checkEqual(1.0, 1.0);
    checkEqual("foo", "foo");
}

void testNotEqual() {
    checkNotEqual(3, 4);
    checkNotEqual(5.0, 6.0);
    checkNotEqual("foo", "bar");
}


private class MyException: Exception {
    this() {
        super("MyException");
    }
}

void testThrown() {
    checkThrown!MyException(throwFunc());
}

void testNotThrown() {
    checkNotThrown(nothrowFunc());
}

private void throwFunc() {
    throw new MyException;
}

private void nothrowFunc() nothrow {
    {}
}

//the tests below should take only 1 second in total if using parallelism
//(given enough cores)
void testLongRunning1() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning2() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning3() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning4() {
    Thread.sleep( dur!"seconds"(1));
}

class TestIo: TestCase {
    override void test() {
        writelnUt("Class writelnUt should only print with '-d' option");
    }
}

void testNoIo1() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
    writelnUt("But this should show up when using -d option");
}


void testNoIo2() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}

void testNoIo3() {
    import std.stdio;
    writeln("This should not be seen except for -d option");
    writeln("Or this");
    stderr.writeln("Stderr shouldn't be seen either");
}


@UnitTest
void funcAttributes() {
    //tests that using the @UnitTest UDA adds this function
    //to the list of tests despite its name
    checkEqual(1, 1);
}

//won't be registered, impossible to instantiate
class BaseAttr: TestCase {
    override void test() {
        doTest();
    }

    abstract void doTest();
}

//will be registered since actually has 'test' method
class Attr: BaseAttr{
    override void doTest() {
        checkEqual(2, 2);
    }
}

//won't be tested due to attribute
@DontTest
void testThatWontRun() {
    checkEqual(1, 2); //doesn't matter, won't run anyway
}

@DontTest
class TestThatWontRun: TestCase {
    override void test() {
        checkNotNull(null); //doesn't matter, won't run anyway
    }
}

@HiddenTest
class HiddenTest: TestCase {
    override void test() {
        checkNotNull(null); //hidden by default, fails if explicitly run
    }
}

@HiddenTest
void testHidden() {
    checkNotNull(null); //hidden by default, fails if explicitly run
}

private void testPrivate() {
    //private function, won't get run
    checkNotNull(null); //won't run, can't fail
}

private class PrivateTest: TestCase {
    override void test() {
        checkNotNull(null); //won't run, can't fail
    }
}

unittest {
    assert(true); //unit test block that always passes
}
