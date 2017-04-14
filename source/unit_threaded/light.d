/**
   This module is an attempt to alleviate compile times by including the bare
   minimum. The idea is that while the reporting usually done by unit-threaded
   is welcome, it only really matters when tests fail. Otherwise, no news is
   good news.

   Likewise, naming and selecting tests are features used when certain tests
   fail. The usual way to run tests is to run all of them and be happy if
   they all pass.

   This module makes it so that unit-threaded gets out of the way, and if
   needed the full features can be turned on at the cost of compiling
   much more slowly.
 */

module unit_threaded.light;


int runTests(T...)(in string[] args) {
    import core.runtime;
    try {
        Runtime.moduleUnitTester();
        return 0;
    } catch(Throwable _)
        return 1;
}
