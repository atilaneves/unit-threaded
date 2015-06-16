module tests.fail.composite;

import unit_threaded;

@singleThreaded
@name("testFunction1") unittest
{
    true.shouldBeTrue;
}

@singleThreaded
@name("testFunction2") unittest
{
    false.shouldBeTrue;
}
