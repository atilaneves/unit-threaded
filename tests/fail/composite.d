module tests.fail.composite;

import unit_threaded.testcase;
import unit_threaded.check;

class SingleThreadedTest: CompositeTestCase!int {
    this() {
        TestCase t1 = new Test1;
        TestCase t2 = new Test2;
        super([t1, t2]);
    }
}

private class Test1: TestCase {
    override void test() {
        print("top of test1\n");
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

private class Test2: TestCase {
    override void test() {
        print("top of test2\n");
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}
