module tests.fail.composite;

import unit_threaded.testcase;
import unit_threaded.should;
import unit_threaded.should;
import unit_threaded.attrs;


@SingleThreaded
class Test1: TestCase {
    override void test() {
        true.shouldBeTrue;
        (2 + 3).shouldEqual(5);
    }
}

@SingleThreaded
class Test2: TestCase {
    override void test() {
        true.shouldBeTrue;
        (2 + 3).shouldEqual(5);
    }
}

@SingleThreaded
class Test3: TestCase {
    override void test() {
        true.shouldBeTrue;
        (2 + 3).shouldEqual(5);
    }
}

@SingleThreaded
class Test4: TestCase {
    override void test() {
        true.shouldBeTrue;
        shouldEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test5: TestCase {
    override void test() {
        true.shouldBeTrue;
        shouldEqual(2 + 3, 5);
    }
}

@SingleThreaded
class Test6: TestCase {
    override void test() {
        true.shouldBeTrue;
        shouldEqual(2 + 3, 5);
    }
}

@SingleThreaded
void testFunction1() {
    true.shouldBeTrue;
}

@SingleThreaded
void testFunction2() {
    shouldBeTrue(false);
}
