module tests.pass.attributes;

import unit_threaded;

enum myEnumNum = "foo.bar"; //there was a bug that made this not compile
enum myOtherEnumNum;

//won't be tested due to attribute
@DontTest
@Name("testThatWontRun") unittest {
    1.shouldEqual(2); //doesn't matter, won't run anyway
}

@HiddenTest
@Name("testHidden") unittest {
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}


@ShouldFail("Bug id 12345")
@Name("testShouldFail") unittest {
    3.shouldEqual(4);
}


@ShouldFail("Bug id 12345")
@Name("testShouldFailWithOtherException") unittest {
    throw new Exception("This should not be seen");
}
