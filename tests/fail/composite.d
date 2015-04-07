module tests.fail.composite;

import unit_threaded.testcase;
import unit_threaded.should;
import unit_threaded.check;
import unit_threaded.attrs;

@SingleThreaded
@Name("testFunction1") unittest
{
    true.shouldBeTrue;
}

@SingleThreaded
@Name("testFunction2") unittest
{
    checkTrue(false);
}
