module tests.fail.composite;

import unit_threaded.testcase;
import unit_threaded.check;

class SingleThreadedTest: CompositeTestCase!(Test1, Test2) {
}

private class Test1: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

private class Test2: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}
