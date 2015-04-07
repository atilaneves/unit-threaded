module tests.fail.normal;

import unit_threaded;


@Name("testTrue") unittest
{
    checkTrue(true);
}

@Name("testEqualVars") unittest
{
    immutable foo = 4;
    immutable bar = 6;
    foo.shouldEqual(bar);
}

@Name("testStringEqual") unittest
{
    "foo".shouldEqual("bar");
}

@Name("testStringEqualFails") unittest
{
    "foo".shouldEqual("bar");
}

@Name("testStringNotEqual") unittest
{
    "foo".shouldNotEqual("foo");
}

unittest
{
    const str = "unittest block that always fails";
    writelnUt(str);
    assert(3 == 4, str);
}

@Name("testIntArray") unittest
{
    [1, 2, 4].shouldEqual([1, 2, 3]);
}

@Name("testStringArray") unittest
{
    ["foo", "baz", "badoooooooooooo!"].shouldEqual(["foo", "bar", "baz"]);
}
