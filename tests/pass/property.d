module tests.pass.property;

import unit_threaded;

@("int[] property")
unittest {
    verifyProperty!((int[] a) => assert(a != [0, 1, 2, 3, 4]));
}
