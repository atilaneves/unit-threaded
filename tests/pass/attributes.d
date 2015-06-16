module tests.pass.attributes;

import unit_threaded;


@hiddenTest
@name("testHidden") unittest
{
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}


@shouldFail("Bug id 12345")
@name("testShouldFail") unittest
{
    3.shouldEqual(4);
}


@shouldFail("Bug id 12345")
@name("testShouldFailWithOtherException") unittest
{
    throw new Exception("This should not be seen");
}
