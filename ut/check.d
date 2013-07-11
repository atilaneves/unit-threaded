module ut.check;
@safe

import std.exception;

class UnitTestException: Exception {
    this(string msg) {
        super(msg);
    }
}

void checkTrue(bool condition, string file = __FILE__, uint line = __LINE__) {
    if(!condition) fail(condition, true, file, line);
}

void checkFalse(bool condition, string file = __FILE__, uint line = __LINE__) {
    if(condition) fail(condition, false, file, line);
}

void checkEqual(T)(T value, T expected, string file = __FILE__, uint line = __LINE__) {
    if(value != expected) fail(value, expected, file, line);
}

void checkNotEqual(T)(T value, T expected, string file = __FILE__, uint line = __LINE__) {
    if(value == expected) fail(value, expected, file, line);
}

private void fail(T)(in T value, in T expected, in string file, in uint line) {
    throw new UnitTestException(getOutput(value, expected, file, line));
}

private string getOutput(T)(in T value, in T expected, in string file, in uint line) {
    import std.conv;
    return "\n    " ~ file ~ ":" ~ to!string(line) ~ " - Value " ~ to!string(value) ~
        " is not the expected " ~ to!string(expected) ~ "\n";
}

private void assertCheck(E)(lazy E expression) {
    assertNotThrown!UnitTestException(expression);
}

unittest {
    assertCheck(checkTrue(true));
    assertCheck(checkFalse(false));
}


unittest {
    assertCheck(checkEqual(1, 1));
    assertCheck(checkEqual("foo", "foo"));
    assertCheck(checkEqual(true, true));
    assertCheck(checkEqual(false, false));
    assertCheck(checkEqual(1.0, 1.0));
    assertCheck(checkNotEqual(1, 2));
    assertCheck(checkNotEqual(true, false));
    assertCheck(checkNotEqual(1.0, 2.0));
}
