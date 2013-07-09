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
