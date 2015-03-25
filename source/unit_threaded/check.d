module unit_threaded.check;

import std.exception;
import std.conv;
import std.algorithm;
import std.traits;
import std.range;

public import unit_threaded.attrs;

class UnitTestException: Exception {
    this(in string msgLines[], in string file, in ulong line) {
        import std.array;
        super(msgLines.map!(a => getOutputPrefix(file, line) ~ a).join("\n"));
    }

private:

    string getOutputPrefix(in string file, in ulong line) {
        return "    " ~ file ~ ":" ~ line.to!string ~ " - ";
    }
}

void checkTrue(E)(lazy E condition, in string file = __FILE__, in ulong line = __LINE__) {
    if(!condition) failEqual(condition, true, file, line);
}

void checkFalse(E)(lazy E condition, in string file = __FILE__, in ulong line = __LINE__) {
    if(condition) failEqual(condition, false, file, line);
}

void checkEqual(T, U)(in T value, in U expected, in string file = __FILE__, in ulong line = __LINE__)
if(is(typeof(value != expected) == bool) && !is(T == class)) {
    if(value != expected) failEqual(value, expected, file, line);
}

void checkEqual(T)(in T value, in T expected, in string file = __FILE__, in ulong line = __LINE__)
if(is(T == class)) {
    if(value.tupleof != expected.tupleof) failEqual(value, expected, file, line);
}


void checkNotEqual(T, U)(in T value, in U expected, in string file = __FILE__, in ulong line = __LINE__)
if(is(typeof(value == expected) == bool)) {
    if(value == expected) {
        auto valueStr = value.to!string;
        static if(is(T == string)) {
            valueStr = `"` ~ valueStr ~ `"`;
        }
        auto expectedStr = expected.to!string;
        static if(is(U == string)) {
            expectedStr = `"` ~ expectedStr ~ `"`;
        }

        const msg = "Value " ~ valueStr ~ " is not supposed to be equal to " ~ expectedStr ~ "\n";
        throw new UnitTestException([msg], file, line);
    }
}

void checkNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__) {
    if(value !is null) fail("Value is null", file, line);
}

void checkNotNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__) {
    if(value is null) fail("Value is null", file, line);
}

void checkIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(isAssociativeArray!U)
{
    if(value !in container) {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file, line);
    }
}

void checkIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(!isAssociativeArray!U)
{
    if(!find(container, value)) {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file, line);
    }
}

void checkNotIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(isAssociativeArray!U)
{
    if(value in container) {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file, line);
    }
}

void checkNotIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(!isAssociativeArray!U)
{
    if(find(container, value).length > 0) {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file, line);
    }
}

void checkThrown(T: Throwable = Exception, E)(lazy E expr, in string file = __FILE__, in ulong line = __LINE__) {
    if(!threw!T(expr)) fail("Expression did not throw", file, line);
}

void checkNotThrown(T: Throwable = Exception, E)(lazy E expr, in string file = __FILE__, in ulong line = __LINE__) {
    if(threw!T(expr)) fail("Expression threw", file, line);
}

private bool threw(T: Throwable, E)(lazy E expr) {
    try {
        expr();
    } catch(T e) {
        return true;
    }

    return false;
}


void utFail(in string output, in string file, in ulong line) {
    fail(output, file, line);
}

private void fail(in string output, in string file, in ulong line) {
    throw new UnitTestException([output], file, line);
}

private void failEqual(T, U)(in T value, in U expected, in string file, in ulong line) {
    static if(isArray!T && !isSomeString!T) {
        const msg = formatArray("Expected: ", expected) ~ formatArray("     Got: ", value);
    } else {
        const msg = ["Expected: " ~ formatValue(expected),
                     "     Got: " ~ formatValue(value)];
    }

    throw new UnitTestException(msg, file, line);
}

private string[] formatArray(T)(in string prefix, in T value) if(isArray!T) {
    import std.range;
    auto defaultLines = [prefix ~ value.to!string];

    static if(!isArray!(ElementType!T)) return defaultLines;
    else {
        const maxElementSize = value.empty ? 0 : value.map!(a => a.length).reduce!max;
        const tooBigForOneLine = (value.length > 5 && maxElementSize > 5) ||
            maxElementSize > 10;
        if(!tooBigForOneLine) return  defaultLines;
        return [prefix ~ "["] ~ value.map!(a => "              " ~ formatValue(a) ~ ",").array ~ "          ]";
    }
}

private auto formatValue(T)(T element) {
    static if(isSomeString!T) {
        return `"` ~ element.to!string ~ `"`;
    } else {
        return element.to!string;
    }
}


private void assertCheck(E)(lazy E expression) {
    assertNotThrown!UnitTestException(expression);
}

unittest {
    assertCheck(checkTrue(true));
    assertCheck(checkFalse(false));
}


unittest {
    assertCheck(checkEqual(true, true));
    assertCheck(checkEqual(false, false));
    assertCheck(checkNotEqual(true, false));

    assertCheck(checkEqual(1, 1));
    assertCheck(checkNotEqual(1, 2));

    assertCheck(checkEqual("foo", "foo"));
    assertCheck(checkNotEqual("f", "b"));

    assertCheck(checkEqual(1.0, 1.0));
    assertCheck(checkNotEqual(1.0, 2.0));

    assertCheck(checkEqual([2, 3], [2, 3]));
    assertCheck(checkNotEqual([2, 3], [2, 3, 4]));

    int[] ints = [ 1, 2, 3];
    byte[] bytes = [ 1, 2, 3];
    byte[] bytes2 = [ 1, 2, 4];
    assertCheck(checkEqual(ints, bytes));
    assertCheck(checkEqual(bytes, ints));
    assertCheck(checkNotEqual(ints, bytes2));

    assertCheck(checkEqual([1: 2.0, 2: 4.0], [1: 2.0, 2: 4.0]));
    assertCheck(checkNotEqual([1: 2.0, 2: 4.0], [1: 2.2, 2: 4.0]));
    const constIntToInts = [ 1:2, 3: 7, 9: 345];
    auto intToInts = [ 1:2, 3: 7, 9: 345];
    assertCheck(checkEqual(intToInts, constIntToInts));
    assertCheck(checkEqual(constIntToInts, intToInts));
}

unittest {
    assertCheck(checkNull(null));
    class Foo { }
    assertCheck(checkNotNull(new Foo));
}

unittest {
    assertCheck(checkIn(4, [1, 2, 4]));
    assertCheck(checkNotIn(3.5, [1.1, 2.2, 4.4]));
    assertCheck(checkIn("foo", ["foo": 1]));
    assertCheck(checkNotIn(1.0, [2.0: 1, 3.0: 2]));
}


void checkEmpty(R)(R rng, in string file = __FILE__, in ulong line = __LINE__) if(isInputRange!R) {
    if(!rng.empty) fail("Range not empty", file, line);
}

void checkEmpty(T)(in T aa, in string file = __FILE__, in ulong line = __LINE__) if(isAssociativeArray!T) {
    if(!aa.keys.empty) fail("AA not empty", file, line);
}


void checkNotEmpty(R)(R rng, in string file = __FILE__, in ulong line = __LINE__) if(isInputRange!R) {
    if(rng.empty) fail("Range empty", file, line);
}


void checkNotEmpty(T)(in T aa, in string file = __FILE__, in ulong line = __LINE__) if(isAssociativeArray!T) {
    if(aa.keys.empty) fail("AA empty", file, line);
}


unittest {
    int[] ints;
    string[] strings;
    string[string] aa;

    assertCheck(checkEmpty(ints));
    assertCheck(checkEmpty(strings));
    assertCheck(checkEmpty(aa));

    assertThrown!UnitTestException(checkNotEmpty(ints));
    assertThrown!UnitTestException(checkNotEmpty(strings));
    assertThrown!UnitTestException(checkNotEmpty(aa));


    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    assertCheck(checkNotEmpty(ints));
    assertCheck(checkNotEmpty(strings));
    assertCheck(checkNotEmpty(aa));

    assertThrown!UnitTestException(checkEmpty(ints));
    assertThrown!UnitTestException(checkEmpty(strings));
    assertThrown!UnitTestException(checkEmpty(aa));
}
