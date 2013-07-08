import ut.testcase;

class WrongTest: TestCase {
    override void test() {
        assertTrue(5 == 3);
        assertFalse(5 == 5);
        assertEqual(5, 5);
        assertNotEqual(5, 3);
        assertEqual(5, 3);
    }
}

class RightTest: TestCase {
    override void test() {
        assertTrue(true);
    }
}

private void testFoo() {}
private void someFun() {}

unittest {
    assert(false, "unittest block that always fails");
}
