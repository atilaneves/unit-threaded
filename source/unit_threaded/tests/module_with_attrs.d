module unit_threaded.tests.module_with_attrs;

import unit_threaded.attrs;

@HiddenTest("foo")
@ShouldFail("bar")
@SingleThreaded
void testAttrs() { }


@ShouldFail
@(1, 2, 3)
void testValues(int i) { }
