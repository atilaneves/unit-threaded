module tests.fail_tests;

import unit_threaded.check;
import unit_threaded.testcase;

import core.time;
import core.thread;


class WrongTest: TestCase {
    override void test() {
        checkTrue(5 == 3);
        checkFalse(5 == 5);
        checkEqual(5, 5);
        checkNotEqual(5, 3);
        checkEqual(5, 3);
    }
}

class OtherWrongTest: TestCase {
    override void test() {
        checkTrue(false);
    }
}

class RightTest: TestCase {
    override void test() {
        checkTrue(true);
    }
}

void testTrue() {
    checkTrue(true);
}

void testEqualVars() {
    immutable foo = 4;
    immutable bar = 6;
    checkEqual(foo, bar);
}

void someFun() {
    //not going to be executed as part of the testsuite,
    //doesn't obey the naming convention
    assert(0, "Never going to happen");
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


unittest {
    assert(false, "unittest block that always fails");
}
