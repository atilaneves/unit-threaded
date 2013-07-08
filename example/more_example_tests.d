import ut.testcase;

class IntTest: TestCase {
    override void test() {
        assertNotEqual(1, 5);
        assertNotEqual(5, 1);
        assertEqual(3, 3);
        assertEqual(2, 2);
    }
}
