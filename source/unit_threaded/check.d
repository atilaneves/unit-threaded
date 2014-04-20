module unit_threaded.check;

import std.exception;
import std.conv;
import std.algorithm;
import std.traits;

public import unit_threaded.attrs;

class UnitTestException: Exception {
    this(string msg) {
        super(msg);
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
        throw new UnitTestException(getOutputPrefix(file, line) ~
                                    "Value " ~ to!string(value) ~
                                    " is not supposed to be equal to " ~
                                    to!string(expected) ~ "\n");
    }
}

void checkNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__) {
    if(value !is null) fail(getOutputPrefix(file, line) ~ "Value is null");
}

void checkNotNull(T)(in T value, in string file = __FILE__, in ulong line = __LINE__) {
    if(value is null) fail(getOutputPrefix(file, line) ~ "Value is null");
}

void checkIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(isAssociativeArray!U)
{
    if(value !in container) {
        fail(getOutputPrefix(file, line) ~ "Value " ~ to!string(value) ~ " not in " ~ to!string(container));
    }
}

void checkIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(!isAssociativeArray!U)
{
    if(!find(container, value)) {
        fail(getOutputPrefix(file, line) ~ "Value " ~ to!string(value) ~ " not in " ~ to!string(container));
    }
}

void checkNotIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(isAssociativeArray!U)
{
    if(value in container) {
        fail(getOutputPrefix(file, line) ~ "Value " ~ to!string(value) ~ " in " ~ to!string(container));
    }
}

void checkNotIn(T, U)(in T value, in U container, in string file = __FILE__, in ulong line = __LINE__)
    if(!isAssociativeArray!U)
{
    if(find(container, value).length > 0) {
        fail(getOutputPrefix(file, line) ~ "Value " ~ to!string(value) ~ " in " ~ to!string(container));
    }
}

void checkThrown(T: Throwable = Exception, E)(lazy E expr, in string file = __FILE__, in ulong line = __LINE__) {
    if(!threw!T(expr)) fail(getOutputPrefix(file, line) ~ "Expression did not throw");
}

void checkNotThrown(T: Throwable = Exception, E)(lazy E expr, in string file = __FILE__, in ulong line = __LINE__) {
    if(threw!T(expr)) fail(getOutputPrefix(file, line) ~ "Expression threw");
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
    fail(getOutputPrefix(file, line) ~ output);
}

private void fail(in string output) {
    throw new UnitTestException(output);
}

private void failEqual(T, U)(in T value, in U expected, in string file, in ulong line) {
    throw new UnitTestException(getOutput(value, expected, file, line));
}

private string getOutput(T, U)(in T value, in U expected, in string file, in ulong line) {
    auto valueStr = value.to!string;
    static if(is(T == string)) {
        valueStr = `"` ~ valueStr ~ `"`;
    }
    auto expectedStr = expected.to!string;
        static if(is(U == string)) {
        expectedStr = `"` ~ expectedStr ~ `"`;
    }

    return getOutputPrefix(file, line) ~
        "Value " ~ valueStr ~
        " is not the expected " ~ expectedStr ~ "\n";
}

private string getOutputPrefix(in string file, in ulong line) {
    return "    " ~ file ~ ":" ~ to!string(line) ~ " - ";
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
