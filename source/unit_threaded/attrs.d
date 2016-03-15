module unit_threaded.attrs;

enum UnitTest; //opt-in to registration
enum DontTest; //opt-out of registration
enum Serial; //run tests in the module in one thread / serially

alias SingleThreaded = Serial;

///Hide test. Not run by default but can be run.
struct HiddenTest {
    string reason;
}

/// The suite fails if the test passes.
struct ShouldFail {
    string reason;
}

/// Associate a name with a unittest block.
struct Name {
    string value;
}

/** Attachs these types to the a parametrized unit test.
    The attached template function will be instantiated with
    each type listed, e.g.

    ----------------
    @Types!(int, byte) void testInit(T)() { T.init.shouldEqual(0); }
    ----------------

    These would mean two testInit test runs.

    Normally this would be a template but I don't know how to write
 *  the UDA code to filter a template out
 */
struct Types(T...) {}


/**
 Used as a UDA for built-in unittests to enable value-parametrized tests.
 Example:
 -------
 @Values(1, 2, 3) unittest { assert(getValue!int % 2 == 0); }
 -------
 The example above results in unit_threaded running the unit tests 3 times,
 once for each value declared.

 See `getValue`.
 */
ValuesImpl!T Values(T)(T[] values...) {
    return ValuesImpl!T(values.dup);
}

struct ValuesImpl(T) {
    T[] values;
}

/**
 Retrieves the current test value of type T in a built-in unittest.
 See `Values`.
 */
T getValue(T)() {
    return ValueHolder!T.value;
}

package struct ValueHolder(T) {
    static T value;
}
