module tests.pass.register;

import unit_threaded;


//won't be registered, impossible to instantiate
class BaseClass: TestCase {
    override void test() {
        doTest();
    }

    abstract void doTest();
}

//will be registered since actually has 'test' method
class DerivedClass: BaseClass{
    override void doTest() {
        2.shouldEqual(2);
    }
}

private void testPrivate() {
    //private function, won't get run
    null.shouldNotBeNull; //won't run, can't fail
}

private class PrivateTest: TestCase {
    override void test() {
        null.shouldNotBeNull; //won't run, can't fail
    }
}
