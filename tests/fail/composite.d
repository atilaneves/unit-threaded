module tests.fail.composite;

import unit_threaded.testcase;
import unit_threaded.check;


@SingleThreaded
class Test1: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test2: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test3: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test4: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test5: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test6: TestCase {
    override void test() {
        checkTrue(true);
        checkEqual(2 + 3, 5);
    }
}
