module example.tests.pass.register;

import unit_threaded.all;


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
        checkEqual(2, 2);
    }
}

private void testPrivate() {
    //private function, won't get run
    checkNotNull(null); //won't run, can't fail
}

private class PrivateTest: TestCase {
    override void test() {
        checkNotNull(null); //won't run, can't fail
    }
}
