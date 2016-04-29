module tests.pass.attributes;

import unit_threaded;

enum myEnumNum = "foo.bar"; //there was a bug that made this not compile
enum myOtherEnumNum;

@Tags("tagged")
@UnitTest
void funcAttributes() {
    //tests that using the @UnitTest UDA adds this function
    //to the list of tests despite its name
    1.shouldEqual(1);
}

//won't be tested due to attribute
@DontTest
void testThatWontRun() {
    1.shouldEqual(2); //doesn't matter, won't run anyway
}

@DontTest
class TestThatWontRun: TestCase {
    override void test() {
        null.shouldNotBeNull; //doesn't matter, won't run anyway
    }
}

@HiddenTest("Bug id #54321")
class MyHiddenTest: TestCase {
    override void test() {
        null.shouldNotBeNull; //hidden by default, fails if explicitly run
    }
}

@HiddenTest
void testHidden() {
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}


@ShouldFail("Bug id 12345")
void testShouldFail() {
    3.shouldEqual(4);
}


@ShouldFail("Bug id 12345")
void testShouldFailWithOtherException() {
    throw new Exception("This should not be seen");
}

@Tags("tagged")
@Name("first_unit_test")
unittest {
    writelnUt("First unit test block\n");
    assert(true); //unit test block that always passes
}


@Name("second_unit_test")
unittest {
    writelnUt("Second unit test block\n");
    assert(true); //unit test block that always passes
}

@Tags(["untagged", "unhinged"])
@("third_unit_test")
unittest {
    3.shouldEqual(3);
}

@ShouldFail
unittest {
    3.shouldEqual(5);
}

@Tags("other", "more")
@(42, 2)
void testValues(int i) {
    (i % 2 == 0).shouldBeTrue;
}


@ShouldFail
void testShouldFailWithAssertionInTestFunction() {
     assert(false);
}

@ShouldFail
@(12, 14)
void testIssue14(int i) {
    (i % 2 == 0).shouldBeFalse;
}

@Types!(int, byte)
void testTemplate(T)() {
    T.init.shouldEqual(0);
}

@("Built-in with values")
@Values("red", "goo")
unittest {
    getValue!string.length.shouldEqual(3);
}
