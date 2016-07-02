module tests.pass.property;

import unit_threaded;

@("int[] property")
unittest {
    // probably as unlikely to happen as quantum tunneling to the moon
    check!((int[] a) => a != [0, 1, 2, 3, 4]);
}

@("int[] sorting twice yields the same result") unittest {
    import std.algorithm: sort;
    check!((int[] a) {
        sort(a);
        auto b = a.dup;
        sort(b);
        return a == b;
    });
}
