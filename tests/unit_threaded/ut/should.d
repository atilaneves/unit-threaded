module unit_threaded.ut.should;

import unit_threaded.should;
import unit_threaded.asserts;

private void assertFail(E)(lazy E expression, in string file = __FILE__, in size_t line = __LINE__)
{
    import std.exception: assertThrown;
    assertThrown!UnitTestException(expression, null, file, line);
}


@safe pure unittest {
    static struct Foo {
        bool opCast(T: bool)() {
            return true;
        }
    }
    shouldBeTrue(Foo());
}


@safe pure unittest {
    static struct Foo {
        bool opCast(T: bool)() {
            return false;
        }
    }
    shouldBeFalse(Foo());
}

@safe unittest {
    //impure comparisons
    shouldEqual(1.0, 1.0) ;
}

@safe pure unittest {
    import unit_threaded.asserts;

    assertExceptionMsg(3.shouldEqual(5),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: 5\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: 3");

    assertExceptionMsg("foo".shouldEqual("bar"),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: \"bar\"\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: \"foo\"");

    assertExceptionMsg([1, 2, 4].shouldEqual([1, 2, 3]),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: [1, 2, 3]\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: [1, 2, 4]");

    assertExceptionMsg([[0, 1, 2, 3, 4], [1], [2], [3], [4], [5]].shouldEqual([[0], [1], [2]]),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: [[0], [1], [2]]\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: [[0, 1, 2, 3, 4], [1], [2], [3], [4], [5]]");

    assertExceptionMsg([[0, 1, 2, 3, 4, 5], [1], [2], [3]].shouldEqual([[0], [1], [2]]),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: [[0], [1], [2]]\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: [[0, 1, 2, 3, 4, 5], [1], [2], [3]]");


    assertExceptionMsg([[0, 1, 2, 3, 4, 5], [1], [2], [3], [4], [5]].shouldEqual([[0]]),
                       "    tests/unit_threaded/ut/should.d:123 - Expected: [[0]]\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -      Got: [\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [0, 1, 2, 3, 4, 5],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [1],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [2],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [3],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [4],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -               [5],\n" ~
                       "    tests/unit_threaded/ut/should.d:123 -           ]");

    assertExceptionMsg(1.shouldNotEqual(1),
                       "    tests/unit_threaded/ut/should.d:123 - Value:\n" ~
                       "    tests/unit_threaded/ut/should.d:123 - 1\n" ~
                       "    tests/unit_threaded/ut/should.d:123 - is not expected to be equal to:\n" ~
                       "    tests/unit_threaded/ut/should.d:123 - 1");
}

@safe pure unittest
{
    ubyte[] arr;
    arr.shouldEqual([]);
}


@safe pure unittest
{
    int[] ints = [1, 2, 3];
    byte[] bytes = [1, 2, 3];
    byte[] bytes2 = [1, 2, 4];
    shouldEqual(ints, bytes);
    shouldEqual(bytes, ints) ;
    shouldNotEqual(ints, bytes2) ;

    const constIntToInts = [1 : 2, 3 : 7, 9 : 345];
    auto intToInts = [1 : 2, 3 : 7, 9 : 345];
    shouldEqual(intToInts, constIntToInts) ;
    shouldEqual(constIntToInts, intToInts) ;
}

@safe unittest {
    shouldEqual([1 : 2.0, 2 : 4.0], [1 : 2.0, 2 : 4.0]) ;
    shouldNotEqual([1 : 2.0, 2 : 4.0], [1 : 2.2, 2 : 4.0]) ;
}


@safe pure unittest
{
    class Foo
    {
        this(int i) { this.i = i; }
        override string toString() const
        {
            import std.conv: to;
            return i.to!string;
        }
        int i;
    }

    shouldNotBeNull(new Foo(4));
    assertFail(shouldNotBeNull(null));
    shouldEqual(new Foo(5), new Foo(5));
    assertFail(shouldEqual(new Foo(5), new Foo(4)));
    shouldNotEqual(new Foo(5), new Foo(4)) ;
    assertFail(shouldNotEqual(new Foo(5), new Foo(5)));
}

@safe pure unittest
{
    shouldBeNull(null);
    assertFail(shouldBeNull(new int));
}


@safe pure unittest {
    5.shouldBeIn([5: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldBeIn(AA(5));
    assertFail(5.shouldBeIn(AA(4)));
}

@safe pure unittest
{
    shouldBeIn(4, [1, 2, 4]);
    shouldBeIn("foo", ["foo" : 1]);
    assertFail("foo".shouldBeIn(["bar"]));
}

@safe pure unittest {
    assertExceptionMsg("foo".shouldBeIn(["quux": "toto"]),
                       `    tests/unit_threaded/ut/should.d:123 - Value "foo"` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 - not in ["quux":"toto"]`);
}

@safe pure unittest {
    assertExceptionMsg("foo".shouldBeIn("quux"),
                       `    tests/unit_threaded/ut/should.d:123 - Value "foo"` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 - not in "quux"`);

}

@safe pure unittest {
    5.shouldNotBeIn([4: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldNotBeIn(AA(4));
    assertFail(5.shouldNotBeIn(AA(5)));
}

@safe pure unittest {
    assertExceptionMsg("quux".shouldNotBeIn(["quux": "toto"]),
                       `    tests/unit_threaded/ut/should.d:123 - Value "quux"` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 - is in ["quux":"toto"]`);
}

@safe pure unittest {
    assertExceptionMsg("foo".shouldNotBeIn("foobar"),
                       `    tests/unit_threaded/ut/should.d:123 - Value "foo"` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 - is in "foobar"`);

}


@safe unittest
{
    auto arrayRangeWithoutLength(T)(T[] array)
    {
        struct ArrayRangeWithoutLength(T)
        {
        private:
            T[] array;
        public:
            T front() const @property
            {
                return array[0];
            }

            void popFront()
            {
                array = array[1 .. $];
            }

            bool empty() const @property
            {
                import std.array;
                return array.empty;
            }
        }
        return ArrayRangeWithoutLength!T(array);
    }
    shouldNotBeIn(3.5, [1.1, 2.2, 4.4]);
    shouldNotBeIn(1.0, [2.0 : 1, 3.0 : 2]);
    shouldNotBeIn(1, arrayRangeWithoutLength([2, 3, 4]));
    assertFail(1.shouldNotBeIn(arrayRangeWithoutLength([1, 2, 3])));
    assertFail("foo".shouldNotBeIn(["foo"]));
}

@safe pure unittest {
    import unit_threaded.asserts;
    void funcThrows(string msg) { throw new Exception(msg); }
    try {
        auto exception = funcThrows("foo bar").shouldThrow;
        assertEqual(exception.msg, "foo bar");
    } catch(Exception e) {
        assert(false, "should not have thrown anything and threw: " ~ e.msg);
    }
}

@safe pure unittest {
    import unit_threaded.asserts;
    void func() {}
    try {
        func.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assertEqual(e.msg, "Expression did not throw");
}

@safe pure unittest {
    import unit_threaded.asserts;
    void funcAsserts() { assert(false, "Oh noes"); }
    try {
        funcAsserts.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assertEqual(e.msg,
                    "Expression threw core.exception.AssertError instead of the expected Exception:\nOh noes");
}

unittest {
    void func() {}
    func.shouldNotThrow;
    void funcThrows() { throw new Exception("oops"); }
    assertFail(shouldNotThrow(funcThrows));
}

@safe pure unittest {
    void funcThrows(string msg) { throw new Exception(msg); }
    funcThrows("foo bar").shouldThrowWithMessage!Exception("foo bar");
    funcThrows("foo bar").shouldThrowWithMessage("foo bar");
    assertFail(funcThrows("boo boo").shouldThrowWithMessage("foo bar"));
    void func() {}
    assertFail(func.shouldThrowWithMessage("oops"));
}

// can't be made pure because of throwExactly, which in turn
// can't be pure because of Object.opEquals
@safe unittest
{
    class CustomException : Exception
    {
        this(string msg = "")
        {
            super(msg);
        }
    }

    class ChildException : CustomException
    {
        this(string msg = "")
        {
            super(msg);
        }
    }

    void throwCustom()
    {
        throw new CustomException();
    }

    throwCustom.shouldThrow;
    throwCustom.shouldThrow!CustomException;

    void throwChild()
    {
        throw new ChildException();
    }

    throwChild.shouldThrow;
    throwChild.shouldThrow!CustomException;
    throwChild.shouldThrow!ChildException;
    throwChild.shouldThrowExactly!ChildException;
    try
    {
        throwChild.shouldThrowExactly!CustomException; //should not succeed
        assert(0, "shouldThrowExactly failed");
    }
    catch (Exception ex)
    {
    }

    void doesntThrow() {}
    assertFail(doesntThrow.shouldThrowExactly!Exception);
}

@safe pure unittest
{
    void throwRangeError()
    {
        ubyte[] bytes;
        bytes = bytes[1 .. $];
    }

    import core.exception : RangeError;

    throwRangeError.shouldThrow!RangeError;
}

@safe pure unittest {
    import std.stdio;

    import core.exception: OutOfMemoryError;

    class CustomException : Exception {
        this(string msg = "", in string file = __FILE__, in size_t line = __LINE__) { super(msg, file, line); }
    }

    void func() { throw new CustomException("oh noes"); }

    func.shouldThrow!CustomException;
    assertFail(func.shouldThrow!OutOfMemoryError);
}


unittest {
    import unit_threaded.asserts;
    class Foo {
        override string toString() @safe pure nothrow const {
            return "Foo";
        }
    }

    auto foo = new const Foo;
    assertEqual(foo.convertToString, "Foo");
}

@safe pure unittest {
    assert(isEqual(1.0, 1.0));
    assert(!isEqual(1.0, 1.0001));
}

@safe unittest {
    assert(isApproxEqual(1.0, 1.0));
    assert(isApproxEqual(1.0, 1.0001));
}

@safe unittest {
    1.0.shouldApproxEqual(1.0001);
    assertFail(2.0.shouldApproxEqual(1.0));
}

@safe pure unittest {
    import std.conv: to;
    import std.range: iota;

    assert(isEqual(2, 2));
    assert(!isEqual(2, 3));

    assert(isEqual(2.1, 2.1));
    assert(!isEqual(2.1, 2.2));

    assert(isEqual("foo", "foo"));
    assert(!isEqual("foo", "fooo"));

    assert(isEqual([1, 2], [1, 2]));
    assert(!isEqual([1, 2], [1, 2, 3]));

    assert(isEqual(iota(2), [0, 1]));
    assert(!isEqual(iota(2), [1, 2, 3]));

    assert(isEqual([[0, 1], [0, 1, 2]], [iota(2), iota(3)]));
    assert(isEqual([[0, 1], [0, 1, 2]], [[0, 1], [0, 1, 2]]));
    assert(!isEqual([[0, 1], [0, 1, 4]], [iota(2), iota(3)]));
    assert(!isEqual([[0, 1], [0]], [iota(2), iota(3)]));

    assert(isEqual([0: 1], [0: 1]));

    const constIntToInts = [1 : 2, 3 : 7, 9 : 345];
    auto intToInts = [1 : 2, 3 : 7, 9 : 345];

    assert(isEqual(intToInts, constIntToInts));
    assert(isEqual(constIntToInts, intToInts));

    class Foo
    {
        this(int i) { this.i = i; }
        override string toString() const { return i.to!string; }
        int i;
    }

    assert(isEqual(new Foo(5), new Foo(5)));
    assert(!isEqual(new Foo(5), new Foo(4)));

    ubyte[] arr;
    assert(isEqual(arr, []));
}

@safe pure unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    shouldBeEmpty(ints);
    shouldBeEmpty(strings);
    shouldBeEmpty(aa);

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    assertFail(shouldBeEmpty(ints));
    assertFail(shouldBeEmpty(strings));
    assertFail(shouldBeEmpty(aa));
}


@safe pure unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    assertFail(shouldNotBeEmpty(ints));
    assertFail(shouldNotBeEmpty(strings));
    assertFail(shouldNotBeEmpty(aa));

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    shouldNotBeEmpty(ints);
    shouldNotBeEmpty(strings);
    shouldNotBeEmpty(aa);
}

@safe pure unittest
{
    shouldBeGreaterThan(7, 5);
}


@safe pure unittest
{
    shouldBeSmallerThan(5, 7);
    assertFail(shouldBeSmallerThan(7, 5));
    assertFail(shouldBeSmallerThan(7, 7));
}

@safe pure unittest {
    "foo"w.shouldEqual("foo");
}

@("Non-copyable types can be asserted on")
@safe pure unittest {

    struct Move {
        int i;
        @disable this(this);
    }

    Move(5).shouldEqual(Move(5));
}

@("issue 88")
@safe pure unittest {

    class C {
        int foo;
        override string toString() @safe pure nothrow const { return null; }
    }

    C c = null;
    c.shouldEqual(c);
    C null_;
    assertFail((new C).shouldEqual(null_));
}

@("issue 89")
unittest {
    class C {
        override string toString() @safe pure nothrow const { return null; }
    }

    auto actual = new C;
    auto expected = new C;

    // these should both pass
    actual.shouldEqual(expected);      // passes: actual.tupleof == expected.tupleof
    [actual].shouldEqual([expected]);  // fails: actual != expected
}

@("non-const toString should compile")
@safe pure unittest {
    class C {
        override string toString() @safe pure nothrow { return null; }
    }
    (new C).shouldEqual(new C);
}

@safe pure unittest {
    ['\xff'].shouldEqual(['\xff']);
}

@safe unittest {
    shouldEqual(new Object, new Object);
}


@("should ==")
@safe pure unittest {
    1.should == 1;
    2.should == 2;
    assertFail(1.should == 2);
    assertExceptionMsg(1.should == 2,
                       `    tests/unit_threaded/ut/should.d:123 - Expected: 2` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 -      Got: 1`);
}

@("should.be ==")
@safe pure unittest {
    1.should.be == 1;
    2.should.be == 2;
    assertFail(1.should.be == 2);
    assertExceptionMsg(1.should.be == 2,
                       `    tests/unit_threaded/ut/should.d:123 - Expected: 2` ~ "\n" ~
                       `    tests/unit_threaded/ut/should.d:123 -      Got: 1`);
}

@("should.not ==")
@safe pure unittest {
    1.should.not == 2;
    assertFail(2.should.not == 2);
}

@("should.not.be ==")
@safe pure unittest {
    1.should.not.be == 2;
    assertFail(2.should.not.be == 2);
}

@("should.throw")
@safe pure unittest {

    void funcOk() {}

    void funcThrows() {
        throw new Exception("oops");
    }

    assertFail(funcOk.should.throw_);
    funcThrows.should.throw_;
}

@("should.be in")
@safe pure unittest {
    1.should.be in [1, 2, 3];
    2.should.be in [1, 2, 3];
    3.should.be in [1, 2, 3];
    assertFail(4.should.be in [1, 2, 3]);
}

@("should.not.be in")
@safe pure unittest {
    4.should.not.be in [1, 2, 3];
    assertFail(1.should.not.be in [1, 2, 3]);
}

@("should ~ for range")
@safe pure unittest {
    [1, 2, 3].should ~ [3, 2, 1];
    [1, 2, 3].should.not ~ [1, 2, 2];
    assertFail([1, 2, 3].should ~ [1, 2, 2]);
}

@("should ~ for float")
@safe unittest {
    1.0.should ~ 1.0001;
    1.0.should.not ~ 2.0;
    assertFail(2.0.should ~ 1.0001);
}
