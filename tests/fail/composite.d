module tests.fail.composite;

import unit_threaded;

@SingleThreaded
@Name("testFunction1") unittest
{
    true.shouldBeTrue;
}

@SingleThreaded
@Name("testFunction2") unittest
{
    false.shouldBeTrue;
}
