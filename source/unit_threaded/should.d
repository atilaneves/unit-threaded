module unit_threaded.should;

import std.exception;
import std.conv;
import std.algorithm;
import std.traits;
import std.range;

public import unit_threaded.attrs;

@safe:

/**
 * An exception to signal that a test case has failed.
 */
class UnitTestException : Exception
{
    this(in string[] msgLines, in string file = __FILE__,
        in ulong line = __LINE__, Throwable next = null)
    {
        super(msgLines.join("\n"), next, file, line);
        this.msgLines = msgLines;
    }

    override string toString() const pure
    {
        return msgLines.map!(a => getOutputPrefix(file, line) ~ a).join("\n");
    }

private:

    const string[] msgLines;

    string getOutputPrefix(in string file, in ulong line) const pure
    {
        return "    " ~ file ~ ":" ~ line.to!string ~ " - ";
    }
}

/**
 * Verify that the condition is `true`.
 * Throws: UnitTestException on failure.
 */
void shouldBeTrue(E)(lazy E condition, in string file = __FILE__, in ulong line = __LINE__)
{
    if (!condition)
        failEqual(condition, true, file, line);
}

unittest
{
    assertOk(shouldBeTrue(true));
}

/**
 * Verify that the condition is `false`.
 * Throws: UnitTestException on failure.
 */
void shouldBeFalse(E)(lazy E condition, in string file = __FILE__, in ulong line = __LINE__)
{
    if (condition)
        failEqual(condition, false, file, line);
}

unittest
{
    assertOk(shouldBeFalse(false));
}

/**
 * Verify that two values are the same.
 * Throws: UnitTestException on failure.
 */
void shouldEqual(T, U)(in T value, in U expected, in string file = __FILE__, in ulong line = __LINE__) if (
        is(typeof(value != expected) == bool) &&  !is(T == class))
{
    if (value != expected)
        failEqual(value, expected, file, line);
}

/**
 * Verify that two values are the same.
 * Throws: UnitTestException on failure
 */
void shouldEqual(T)(in T value, in T expected, in string file = __FILE__, in ulong line = __LINE__) if (
        is(T == class))
{
    if (value.tupleof != expected.tupleof)
        failEqual(value, expected, file, line);
}

/**
 * Verify that two values are not the same.
 * Throws: UnitTestException on failure
 */
void shouldNotEqual(T, U)(in T value, in U expected, in string file = __FILE__,
    in ulong line = __LINE__) if (is(typeof(value == expected) == bool))
{
    if (() @trusted { return value == expected; }()) //object.opEquals
    {
        auto valueStr = () @trusted { return value.to!string; }();
        static if (is(T == string))
        {
            valueStr = `"` ~ valueStr ~ `"`;
        }
        auto expectedStr = () @trusted { return expected.to!string; }();
        static if (is(U == string))
        {
            expectedStr = `"` ~ expectedStr ~ `"`;
        }

        const msg = "Value " ~ valueStr ~ " is not supposed to be equal to " ~ expectedStr ~ "\n";
        throw new UnitTestException([msg], file, line);
    }
}

unittest
{
    assertOk(shouldEqual(true, true));
    assertOk(shouldEqual(false, false));
    assertOk(shouldNotEqual(true, false));

    assertOk(shouldEqual(1, 1));
    assertOk(shouldNotEqual(1, 2));

    assertOk(shouldEqual("foo", "foo"));
    assertOk(shouldNotEqual("f", "b"));

    assertOk(shouldEqual(1.0, 1.0));
    assertOk(shouldNotEqual(1.0, 2.0));

    assertOk(shouldEqual([2, 3], [2, 3]));
    assertOk(shouldNotEqual([2, 3], [2, 3, 4]));
}

unittest
{
    int[] ints = [1, 2, 3];
    byte[] bytes = [1, 2, 3];
    byte[] bytes2 = [1, 2, 4];
    assertOk(shouldEqual(ints, bytes));
    assertOk(shouldEqual(bytes, ints));
    assertOk(shouldNotEqual(ints, bytes2));

    assertOk(shouldEqual([1 : 2.0, 2 : 4.0], [1 : 2.0, 2 : 4.0]));
    assertOk(shouldNotEqual([1 : 2.0, 2 : 4.0], [1 : 2.2, 2 : 4.0]));
    const constIntToInts = [1 : 2, 3 : 7, 9 : 345];
    auto intToInts = [1 : 2, 3 : 7, 9 : 345];
    assertOk(shouldEqual(intToInts, constIntToInts));
    assertOk(shouldEqual(constIntToInts, intToInts));
}

/**
 * Verify that the value is null.
 * Throws: UnitTestException on failure
 */
void shouldBeNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__)
{
    if (value !is null)
        fail("Value is null", file, line);
}

/**
 * Verify that the value is not null.
 * Throws: UnitTestException on failure
 */
void shouldNotBeNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__)
{
    if (value is null)
        fail("Value is null", file, line);
}

unittest
{
    assertOk(shouldBeNull(null));
    class Foo
    {
    }

    assertOk(shouldNotBeNull(new Foo));
}

/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
*/
void shouldBeIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__) if (
        isAssociativeArray!U)
{
    if (value !in container)
    {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file,
            line);
    }
}

/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
 */
void shouldBeIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__) if (
        !isAssociativeArray!U)
{
    if (find(container, value).empty)
    {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file,
            line);
    }
}

/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(in T value, in U container, in string file = __FILE__,
    in ulong line = __LINE__) if (isAssociativeArray!U)
{
    if (value in container)
    {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file,
            line);
    }
}

unittest
{
    assertOk(shouldBeIn(4, [1, 2, 4]));
    assertOk(shouldNotBeIn(3.5, [1.1, 2.2, 4.4]));
    assertOk(shouldBeIn("foo", ["foo" : 1]));
    assertOk(shouldNotBeIn(1.0, [2.0 : 1, 3.0 : 2]));
}

/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(in T value, in U container, in string file = __FILE__,
    in ulong line = __LINE__) if (!isAssociativeArray!U)
{
    if (find(container, value).length > 0)
    {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file,
            line);
    }
}

/**
 * Verify that expr throws the templated Exception class.
 * This succeeds if the expression throws a child class of
 * the template parameter.
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
void shouldThrow(T : Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in ulong line = __LINE__)
{
    if (!threw!T(expr))
        fail("Expression did not throw", file, line);
}

/**
 * Verify that expr throws the templated Exception class.
 * This only succeeds if the expression throws an exception of
 * the exact type of the template parameter.
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
void shouldThrowExactly(T : Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in ulong line = __LINE__)
{

    immutable threw = threw!T(expr);
    if (!threw)
        fail("Expression did not throw", file, line);

    //Object.opEquals is @system
    immutable sameType = () @trusted{ return threw.typeInfo == typeid(T); }();
    if (!sameType)
        fail(text("Expression threw wrong type ", threw.typeInfo,
            "instead of expected type ", typeid(T)), file, line);
}

/**
 * Verify that expr does not throw the templated Exception class.
 * Throws: UnitTestException on failure
 */
void shouldNotThrow(T : Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in ulong line = __LINE__)
{
    if (threw!T(expr))
        fail("Expression threw", file, line);
}

//@trusted because the user might want to catch a throwable
//that's not derived from Exception, such as RangeError
private auto threw(T : Throwable, E)(lazy E expr) @trusted
{

    struct ThrowResult
    {
        bool threw;
        TypeInfo typeInfo;
        T opCast(T)() const pure if (is(T == bool))
        {
            return threw;
        }
    }

    try
    {
        expr();
    }
    catch (T e)
    {
        return ThrowResult(true, typeid(e));
    }

    return ThrowResult(false);
}

unittest
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
}

unittest
{
    void throwRangeError()
    {
        ubyte[] bytes;
        bytes = bytes[1 .. $];
    }

    import core.exception : RangeError;

    throwRangeError.shouldThrow!RangeError;
}

package void utFail(in string output, in string file, in ulong line)
{
    fail(output, file, line);
}

private void fail(in string output, in string file, in ulong line)
{
    throw new UnitTestException([output], file, line);
}

private void failEqual(T, U)(in T value, in U expected, in string file, in ulong line)
{
    static if (isArray!T && !isSomeString!T)
    {
        const msg = formatArray("Expected: ", expected) ~ formatArray("     Got: ",
            value);
    }
    else
    {
        const msg = ["Expected: " ~ formatValue(expected), "     Got: " ~ formatValue(value)];
    }

    throw new UnitTestException(msg, file, line);
}

private string[] formatArray(T)(in string prefix, in T value) if (isArray!T)
{
    import std.range;

    //some versions of `to` are @system
    auto defaultLines = () @trusted{ return [prefix ~ value.to!string]; }();

    static if (!isArray!(ElementType!T))
        return defaultLines;
    else
    {
        const maxElementSize = value.empty ? 0 : value.map!(a => a.length).reduce!max;
        const tooBigForOneLine = (value.length > 5 && maxElementSize > 5) || maxElementSize > 10;
        if (!tooBigForOneLine)
            return defaultLines;
        return [prefix ~ "["] ~ value.map!(a => "              " ~ formatValue(a) ~ ",").array ~ "          ]";
    }
}

unittest
{
    ubyte[] arr;
    arr.shouldEqual([]);
}

private auto formatValue(T)(T element)
{
    static if (isSomeString!T)
    {
        return `"` ~ element.to!string ~ `"`;
    }
    else
    {
        return () @trusted{ return element.to!string; }();
    }
}

private void assertOk(E)(lazy E expression)
{
    assertNotThrown!UnitTestException(expression);
}

private void assertFail(E)(lazy E expression)
{
    assertThrown!UnitTestException(expression);
}

/**
 * Verify that rng is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(R)(R rng, in string file = __FILE__, in ulong line = __LINE__) if (
        isInputRange!R)
{
    if (!rng.empty)
        fail("Range not empty", file, line);
}

/**
 * Verify that aa is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(T)(in T aa, in string file = __FILE__, in ulong line = __LINE__) if (
        isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (!aa.keys.empty)
        fail("AA not empty", file, line); }();
}

/**
 * Verify that rng is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(R)(R rng, in string file = __FILE__, in ulong line = __LINE__) if (
        isInputRange!R)
{
    if (rng.empty)
        fail("Range empty", file, line);
}

/**
 * Verify that aa is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(T)(in T aa, in string file = __FILE__, in ulong line = __LINE__) if (
        isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (aa.keys.empty)
        fail("AA empty", file, line); }();
}

unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    assertOk(shouldBeEmpty(ints));
    assertOk(shouldBeEmpty(strings));
    assertOk(shouldBeEmpty(aa));

    assertFail(shouldNotBeEmpty(ints));
    assertFail(shouldNotBeEmpty(strings));
    assertFail(shouldNotBeEmpty(aa));

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    assertOk(shouldNotBeEmpty(ints));
    assertOk(shouldNotBeEmpty(strings));
    assertOk(shouldNotBeEmpty(aa));

    assertFail(shouldBeEmpty(ints));
    assertFail(shouldBeEmpty(strings));
    assertFail(shouldBeEmpty(aa));
}

/**
 * Verify that t is greater than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeGreaterThan(T, U)(in T t, in U u, in string file = __FILE__, in ulong line = __LINE__)
{
    if (t <= u)
        fail(text(t, " is not > ", u), file, line);
}

/**
 * Verify that t is smaller than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeSmallerThan(T, U)(in T t, in U u, in string file = __FILE__, in ulong line = __LINE__)
{
    if (t >= u)
        fail(text(t, " is not < ", u), file, line);
}

unittest
{
    assertOk(shouldBeGreaterThan(7, 5));
    assertFail(shouldBeGreaterThan(5, 7));
    assertFail(shouldBeGreaterThan(7, 7));

    assertOk(shouldBeSmallerThan(5, 7));
    assertFail(shouldBeSmallerThan(7, 5));
    assertFail(shouldBeSmallerThan(7, 7));
}
