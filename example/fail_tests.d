import ut.check;
import ut.testcase;

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

void someFun() {} //not going to be executed as part of the testsuite


//the tests below should take only 1 second if using parallelism
void testLongRunning1() {
    Thread.sleep( dur!("seconds")(1));
}

void testLongRunning2() {
    Thread.sleep( dur!("seconds")(1));
}

void testLongRunning3() {
    Thread.sleep( dur!("seconds")(1));
}


unittest {
    assert(false, "unittest block that always fails");
}

unittest {
    assert(false, "other unittest block that always fails");
}
