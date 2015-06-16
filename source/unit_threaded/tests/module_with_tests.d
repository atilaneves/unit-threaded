module unit_threaded.tests.module_with_tests;

import unit_threaded.attrs;


unittest {
    //1st block
    assert(true);
}

unittest {
    //2nd block
    assert(true);
}

@name("myUnitTest")
unittest {
    assert(true);
}
