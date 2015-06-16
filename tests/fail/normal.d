module tests.fail.normal;

import unit_threaded;


@name("testTrue") unittest
{
    true.shouldBeTrue;
}

@name("testEqualVars") unittest
{
    immutable foo = 4;
    immutable bar = 6;
    foo.shouldEqual(bar);
}

@name("testStringEqual") unittest
{
    "foo".shouldEqual("bar");
}

@name("testStringEqualFails") unittest
{
    "foo".shouldEqual("bar");
}

@name("testStringNotEqual") unittest
{
    "foo".shouldNotEqual("foo");
}

unittest
{
    const str = "unittest block that always fails";
    writelnUt(str);
    assert(3 == 4, str);
}

@name("testIntArray") unittest
{
    [1, 2, 4].shouldEqual([1, 2, 3]);
}

@name("testStringArray") unittest
{
    ["foo", "baz", "badoooooooooooo!"].shouldEqual(["foo", "bar", "baz"]);
}
