module example.tests.pass.normal;

import unit_threaded.all;


class IntEqualTest: TestCase {
    override void test() {
        checkNotEqual(1, 5);
        checkNotEqual(5, 1);
        checkEqual(3, 3);
        checkEqual(2, 2);
    }
}

class DoubleEqualTest: TestCase {
    override void test() {
        checkNotEqual(1.0, 2.0);
        checkEqual(2.0, 2.0);
        checkEqual(2.0, 2.0);
    }
}

void testEqual() {
    checkEqual(1, 1);
    checkEqual(1.0, 1.0);
    checkEqual("foo", "foo");
}

void testNotEqual() {
    checkNotEqual(3, 4);
    checkNotEqual(5.0, 6.0);
    checkNotEqual("foo", "bar");
}


private class MyException: Exception {
    this() {
        super("MyException");
    }
}

void testThrown() {
    checkThrown!MyException(throwFunc());
}

void testNotThrown() {
    checkNotThrown(nothrowFunc());
}

private void throwFunc() {
    throw new MyException;
}

private void nothrowFunc() nothrow {
    {}
}

unittest {
    assert(true); //unit test block that always passes
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

    checkEqual(foo, bar);
    checkEqual(bar, foo);
    checkNotEqual(foo, baz);
    checkNotEqual(bar, baz);
    checkNotEqual(baz, foo);
    checkNotEqual(baz, bar);
}
