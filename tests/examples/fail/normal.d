module tests.fail.normal;


import unit_threaded;


@("wrong.0")
unittest {
    shouldBeTrue(5 == 3);
    shouldBeFalse(5 == 5);
    5.shouldEqual(5);
    5.shouldNotEqual(3);
    5.shouldEqual(3);
}


@("wrong.1")
unittest {
    shouldBeTrue(false);
}


@("right")
unittest {
    shouldBeTrue(true);
}

@("true")
unittest {
    shouldBeTrue(true);
}

@("equalVars")
unittest {
    immutable foo = 4;
    immutable bar = 6;
    foo.shouldEqual(bar);
}

void someFun() {
    //not going to be executed as part of the testsuite
    assert(0, "Never going to happen");
}

@("stringEqual")
unittest {
    "foo".shouldEqual("bar");
}

@("stringEqualFails")
unittest {
    "foo".shouldEqual("bar");
}

@("stringNotEqual")
unittest {
    "foo".shouldNotEqual("foo");
}

unittest {
    const str = "unittest block that always fails";
    writelnUt(str);
    assert(3 == 4, str);
}

@("intArray")
unittest {
    [1, 2, 4].shouldEqual([1, 2, 3]);
}

@("stringArray")
unittest {
    ["foo", "baz", "badoooooooooooo!"].shouldEqual(["foo", "bar", "baz"]);
}
