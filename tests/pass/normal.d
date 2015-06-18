module tests.pass.normal;

import unit_threaded;

@name("testEqual") unittest
{
    1.shouldEqual(1);
    shouldEqual(1.0, 1.0);
    "foo".shouldEqual("foo");
}

@name("testNotEqual") unittest
{
    3.shouldNotEqual(4);
    shouldNotEqual(5.0, 6.0);
    "foo".shouldNotEqual("bar");
}


private class MyException: Exception
{
    this()
    {
        super("MyException");
    }
}

@name("testThrown") unittest
{
    void throwFunc()
    {
        throw new MyException;
    }

    throwFunc.shouldThrow!MyException;
}

@name("testNotThrown") unittest
{
    void nothrowFunc() nothrow
    {
    }

    nothrowFunc.shouldNotThrow;
}

@name("first_unit_test")
unittest
{
    writelnUt("First unit test block\n");
    assert(true); //unit test block that always passes
}

@name("second_unit_test")
unittest
{
    writelnUt("Second unit test block\n");
    assert(true); //unit test block that always passes
}


private class MyClass
{
    int i;
    double d;
    this(int i, double d)
    {
        this.i = i;
        this.d = d;
    }
    override string toString() const
    {
        import std.conv;
        return text("MyClass(", i, ", ", d, ")");
    }
}

@name("testEqualClass") unittest
{
    const foo = new MyClass(2, 3.0);
    const bar = new MyClass(2, 3.0);
    const baz = new MyClass(3, 3.0);

    foo.shouldEqual(bar);
    bar.shouldEqual(foo);
    foo.shouldNotEqual(baz);
    bar.shouldNotEqual(baz);
    baz.shouldNotEqual(foo);
    baz.shouldNotEqual(bar);
}


private struct Pair
{
    string s;
    int i;
}

@name("testPairAA") unittest
{
    auto map = [Pair("foo", 5): 105];
    [Pair("foo", 5): 105].shouldEqual(map);
    map.dup.shouldEqual(map);
    auto pair = Pair("foo", 5);
    auto othermap = [pair: 105];
    map.shouldEqual(othermap);
}

@name("range") unittest
{
    import std.range: iota;
    iota(3).shouldEqual([0, 1, 2]);
}
