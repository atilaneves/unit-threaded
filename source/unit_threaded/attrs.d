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
