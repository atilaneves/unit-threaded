module tests.pass.attributes;

import unit_threaded.all;

enum myEnumNum = "foo.bar"; //there was a bug that made this not compile
enum myOtherEnumNum;

@UnitTest
void funcAttributes() {
    //tests that using the @UnitTest UDA adds this function
    //to the list of tests despite its name
    checkEqual(1, 1);
}

//won't be tested due to attribute
@DontTest
void testThatWontRun() {
    checkEqual(1, 2); //doesn't matter, won't run anyway
}

@DontTest
class TestThatWontRun: TestCase {
    override void test() {
        checkNotNull(null); //doesn't matter, won't run anyway
    }
}

@HiddenTest("Bug id #54321")
class MyHiddenTest: TestCase {
    override void test() {
        checkNotNull(null); //hidden by default, fails if explicitly run
    }
}

@HiddenTest
void testHidden() {
    checkNotNull(null); //hidden by default, fails if explicitly run
}


@ShouldFail("Bug id 12345")
void testShouldFail() {
    checkEqual(3, 4);
}


@ShouldFail("Bug id 12345")
void testShouldFailWithOtherException() {
    throw new Exception("This should not be seen");
}
