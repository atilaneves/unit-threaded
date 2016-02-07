module tests.pass.normal;

import unit_threaded;


class IntEqualTest: TestCase {
    override void test() {
        1.shouldNotEqual(5);
        5.shouldNotEqual(1);
        3.shouldEqual(3);
        2.shouldEqual(2);
    }
}

class DoubleEqualTest: TestCase {
    override void test() {
        shouldNotEqual(1.0, 2.0);
        (2.0).shouldEqual(2.0);
        (2.0).shouldEqual(2.0);
    }
}

void testEqual() {
    1.shouldEqual(1);
    shouldEqual(1.0, 1.0);
    "foo".shouldEqual("foo");
}

void testNotEqual() {
    3.shouldNotEqual(4);
    shouldNotEqual(5.0, 6.0);
    "foo".shouldNotEqual("bar");
}


private class MyException: Exception {
    this() {
        super("MyException");
    }
}

void testThrown() {
    throwFunc.shouldThrow!MyException;
}

void testNotThrown() {
    nothrowFunc.shouldNotThrow;
}

private void throwFunc() {
    throw new MyException;
}

private void nothrowFunc() nothrow {
    {}
}

private class MyClass {
    int i;
    double d;
    this(int i, double d) {
        this.i = i;
        this.d = d;
    }
    override string toString() const {
        import std.conv;
        return text("MyClass(", i, ", ", d, ")");
    }
}

void testEqualClass() {
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


private struct Pair {
    string s;
    int i;
}

void testPairAA() {
    auto map = [Pair("foo", 5): 105];
    [Pair("foo", 5): 105].shouldEqual(map);
    map.dup.shouldEqual(map);
    auto pair = Pair("foo", 5);
    auto othermap = [pair: 105];
    map.shouldEqual(othermap);
}
