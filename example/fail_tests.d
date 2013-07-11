import ut.check;
import ut.testcase;

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

void testBar() {
    immutable foo = 4;
    immutable bar = 6;
    checkEqual(foo, bar);
}

void someFun() {}

unittest {
    //TODO: reenable
    //assert(false, "unittest block that always fails");
}
