module tests.pass.fixtures;

import unit_threaded;

class Fixture: TestCase
{
    override void setup()
    {
        // do initialization common for test1 and test2
    }
}

class Test1: Fixture
{
    override void test()
    {
        // testing feature #1
    }
}

class Test2: Fixture
{
    override void test()
    {
        // testing feature #2
    }
}
