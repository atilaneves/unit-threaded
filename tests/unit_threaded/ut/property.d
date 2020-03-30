module unit_threaded.ut.property;

import unit_threaded.property;
import unit_threaded.asserts;

@("Verify anti-identity property for int[] fails")
@safe unittest {
    import unit_threaded.should;
    int numCalls;
    bool antiIdentity(int[] a) {
        ++numCalls;
        return a != a;
    }

    check!antiIdentity.shouldThrow!UnitTestException;
    // gets called twice due to shrinking
    numCalls.shouldEqual(2);
}

@("Verify property that sometimes succeeds")
@safe unittest {
    // 2^100 is ~1.26E30, so the chances that no even length array is generated
    // is small enough to disconsider even if it were truly random
    // since Gen!int[] is front-loaded, it'll fail deterministically
    assertExceptionMsg(check!((int[] a) => a.length % 2 == 1)(42),
                       "    tests/unit_threaded/ut/property.d:123 - Property failed. Seed: 42. Input: []");
}


@("shrink int when already shrunk")
@safe pure unittest {
    assertEqual(0.shrink!(a => a != 0), 0);
}


@("shrink int when not already shrunk going up")
@safe pure unittest {
    assertEqual(0.shrink!(a => a > 3), 3);
}

@("shrink int when not already shrunk going down")
@safe pure unittest {
    assertEqual(10.shrink!(a => a < -3), -3);
}

@("shrink int.max")
@safe pure unittest {
    assertEqual(int.max.shrink!(a => a == 0), 1);
    assertEqual(int.min.shrink!(a => a == 0), -1);
    assertEqual(int.max.shrink!(a => a < 3), 3);
}

@("shrink unsigneds")
@safe pure unittest {
    import std.meta;
    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong)) {
        T value = 3;
        assertEqual(value.shrink!(a => a == 0), 1);
    }
}

@("shrink empty int array")
@safe pure unittest {
    int[] value;
    assertEqual(value.shrink!(a => a != []), value);
}

@("shrink int array")
@safe pure unittest {
    assertEqual([1, 2, 3].shrink!(a => a == []), [1]);
}

@("shrink string")
@safe pure unittest {
    import std.algorithm: canFind;
    assertEqual("abcdef".shrink!(a => !a.canFind("e")), "e");
}

@("shrink one item with check")
unittest {
    assertEqual("ǭĶƶØľĶĄÔ0".shrink!((s) => s.length < 3 || s[2] == 'e'), "ǭ");
}

@("shrink one item with check")
unittest {
    assertExceptionMsg(check!((int i) => i < 3)(33),
                       "    tests/unit_threaded/ut/property.d:123 - Property failed. Seed: 33. Input: 3");
}

@("string[]")
unittest {
    bool identity(string[] a) pure {
        return a == a;
    }
    check!identity;
}

@("property test on user defined struct")
unittest {
    struct Foo {
        int i;
        short s;
    }

    bool identity(Foo f) pure {
        return f == f;
    }

    check!identity;
}

@("issue 93 uint")
unittest {
    import unit_threaded.should;
    check!((uint i) => i != i)(77).shouldThrowWithMessage("Property failed. Seed: 77. Input: 0");
}

@("issue 93 array")
unittest {
    import unit_threaded.should;
    check!((int[] i) => i != i)(11).shouldThrowWithMessage("Property failed. Seed: 11. Input: []");
}

@("check function that throws is the same as check function that returns false")
@safe unittest {
    import unit_threaded.should;
    bool funcThrows(uint) {
        throw new Exception("Fail!");
    }
    check!funcThrows(42).shouldThrowWithMessage("Property threw. Seed: 42. Input: 0. Message: Fail!");
}
