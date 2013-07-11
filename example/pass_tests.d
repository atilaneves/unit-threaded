import ut.check;
import ut.testcase;

class IntTest: TestCase {
    override void test() {
        assertNotEqual(1, 5);
        assertNotEqual(5, 1);
        assertEqual(3, 3);
        assertEqual(2, 2);
    }
}

class DoubleTest: TestCase {
    override void test() {
        assertNotEqual(1.0, 2.0);
        assertEqual(2.0, 2.0);
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
