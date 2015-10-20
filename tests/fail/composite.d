module tests.fail.composite;

import unit_threaded;

@serial
@name("testFunction1") unittest
{
    true.shouldBeTrue;
}

@serial
@name("testFunction2") unittest
{
    false.shouldBeTrue;
}
