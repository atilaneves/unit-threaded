module unit_threaded.tests.module_with_attrs;

import unit_threaded.attrs;

@hiddenTest("foo")
@shouldFail("bar")
@singleThreaded
void testAttrs() {
}
