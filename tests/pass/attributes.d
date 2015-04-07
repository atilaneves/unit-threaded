module tests.pass.attributes;

import unit_threaded;


@HiddenTest
@Name("testHidden") unittest
{
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}


@ShouldFail("Bug id 12345")
@Name("testShouldFail") unittest
{
    3.shouldEqual(4);
}


@ShouldFail("Bug id 12345")
@Name("testShouldFailWithOtherException") unittest
{
    throw new Exception("This should not be seen");
}
