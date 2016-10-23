module unit_threaded.tests.module_with_setup;

import unit_threaded.attrs;

int gNumBefore;
int gNumAfter;

@Setup
void before() {
    ++gNumBefore;
}

@Shutdown
void after() {
    ++gNumAfter;
}

unittest {
    assert(1 == 1);
}

unittest {
    assert(1 == 2);
}
