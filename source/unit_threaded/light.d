/**
   This module is an attempt to alleviate compile times by including the bare
   minimum. The idea is that while the reporting usually done by unit-threaded
   is welcome, it only really matters when tests fail. Otherwise, no news is
   good news.

   Likewise, naming and selecting tests are features used when certain tests
   fail. The usual way to run tests is to run all of them and be happy if
   they all pass.

   This module makes it so that unit-threaded gets out of the way, and if
   needed the full features can be turned on at the cost of compiling
   much more slowly.

   There aren't even any template constraints on the `should` functions
   to avoid imports as much as possible.
 */
module unit_threaded.light;

alias UnitTestException = Exception;


/**
   Dummy version so "normal" code compiles
 */
mixin template runTestsMain(Modules...) if(Modules.length > 0) {
    int main() {
        import unit_threaded.light: runTestsImpl;
        return runTestsImpl;
    }
}

/**
   Dummy version of runTests so "normal" code compiles.
 */
int runTests(T...)(in string[] args) {
    return runTestsImpl;
}

/// ditto
int runTests(T)(string[] args, T testData) {
    return runTestsImpl;
}

int runTestsImpl() {
    import core.runtime: Runtime;
    import core.stdc.stdio: printf;

    version(Posix)
        printf("\033[32;1mOk\033[0;;m");
    else
        printf("Ok");

    printf(": All tests passed\n\n");

    return 0;
}


/**
   Dummy version so "normal" code compiles
 */
int[] allTestData(T...)() {
    return [];
}

/**
   No-op version of writelnUt
 */
void writelnUt(T...)(auto ref T args) {

}

/**
   Same as unit_threaded.property.check
 */
void check(alias F)(int numFuncCalls = 100,
                    string file = __FILE__, size_t line = __LINE__) {
    import unit_threaded.property: utCheck = check;
    utCheck!F(numFuncCalls, file, line);
}

/**
   Same as unit_threaded.property.checkCustom
 */
void checkCustom(alias Generator, alias Predicate)
                (int numFuncCalls = 100, string file = __FILE__, size_t line = __LINE__) {
    import unit_threaded.property: utCheckCustom = checkCustom;
    utCheckCustom!(Generator, Predicate)(numFuncCalls, file, line);
}


/**
   Generic output interface
 */
interface Output {
    void send(in string output) @safe;
    void flush() @safe;
}

/**
   Dummy version of unit_threaded.testcase.TestCase
 */
class TestCase {
    abstract void test();
    void setup() {}
    void shutdown() {}
    static TestCase currentTest() { return new class TestCase { override void test() {}}; }
    Output getWriter() { return new class Output { override void send(in string output) {} override void flush() {}}; }
}


/**
   Same as unit_threaded.mock.mock
 */
auto mock(T)() {
    import unit_threaded.mock: utMock = mock;
    return utMock!T;
}

/**
   Same as unit_threaded.mock.mockStruct
 */
auto mockStruct(T...)(auto ref T returns) {
    import unit_threaded.mock: utMockStruct = mockStruct;
    return utMockStruct(returns);
}

/**
   Throw if condition is not true.
 */
void shouldBeTrue(E)(lazy E condition, string file = __FILE__, size_t line = __LINE__) {
    assert_(cast(bool)condition(), file, line);
}

/// Throw if condition not false.
void shouldBeFalse(E)(lazy E condition, string file = __FILE__, size_t line = __LINE__) {
    assert_(!cast(bool)condition(), file, line);
}

/// Assert value is equal to expected
void shouldEqual(V, E)(auto ref V value, auto ref E expected, string file = __FILE__, size_t line = __LINE__) {

    void checkInputRange(T)(auto ref const(T) _) @trusted {
        auto obj = cast(T) _;
        bool e = obj.empty;
        auto f = obj.front;
        obj.popFront;
    }
    enum isInputRange(T) = is(T: Elt[], Elt) || is(typeof(checkInputRange(T.init)));

    static if(is(V == class)) {

        import unit_threaded.should: isEqual;
        assert_(isEqual(value, expected), file, line);

    } else static if(isInputRange!V && isInputRange!E) {

        auto ref unqual(OriginalType)(auto ref OriginalType obj) @trusted {

            // copied from std.traits
            template Unqual(T) {
                     static if (is(T U ==          immutable U)) alias Unqual = U;
                else static if (is(T U == shared inout const U)) alias Unqual = U;
                else static if (is(T U == shared inout       U)) alias Unqual = U;
                else static if (is(T U == shared       const U)) alias Unqual = U;
                else static if (is(T U == shared             U)) alias Unqual = U;
                else static if (is(T U ==        inout const U)) alias Unqual = U;
                else static if (is(T U ==        inout       U)) alias Unqual = U;
                else static if (is(T U ==              const U)) alias Unqual = U;
                else                                             alias Unqual = T;
            }

            static if(__traits(compiles, obj[])) {
                static if(!is(typeof(obj[]) == OriginalType)) {
                    return unqual(obj[]);
                } else static if(__traits(compiles, cast(Unqual!OriginalType) obj)) {
                    return cast(Unqual!OriginalType) obj;
                } else {
                    return obj;
                }
            } else  static if(__traits(compiles, cast(Unqual!OriginalType) obj)) {
                return cast(Unqual!OriginalType) obj;
            } else
                return obj;
        }

        auto ref unvoid(OriginalType)(auto ref OriginalType obj) @trusted {
            static if(is(OriginalType == void[]))
                return cast(ubyte[]) obj;
            else
                return obj;
        }

        import std.algorithm: equal;
        assert_(equal(unvoid(unqual(value)), unvoid(unqual(expected))), file, line);

    } else {
        assert_(value == expected, file, line);
    }
}



/// Assert value is not equal to expected.
void shouldNotEqual(V, E)(const scope auto ref V value, const scope auto ref E expected, string file = __FILE__, size_t line = __LINE__) {
    assert_(value != expected, file, line);
}

/// Assert value is null.
void shouldBeNull(T)(const scope auto ref T value, string file = __FILE__, size_t line = __LINE__) {
    assert_(value is null, file, line);
}

/// Assert value is not null
void shouldNotBeNull(T)(const scope auto ref T value, string file = __FILE__, size_t line = __LINE__) {
    assert_(value !is null, file, line);
}

enum isLikeAssociativeArray(T, K) = is(typeof({
    if(K.init in T) { }
    if(K.init !in T) { }
}));
static assert(isLikeAssociativeArray!(string[string], string));
static assert(!isLikeAssociativeArray!(string[string], int));


/// Assert that value is in container.
void shouldBeIn(T, U)(const scope auto ref T value, const scope auto ref U container, string file = __FILE__, size_t line = __LINE__)
    if(isLikeAssociativeArray!(U, T)) {
    assert_(cast(bool)(value in container), file, line);
}

/// ditto.
void shouldBeIn(T, U)(const scope auto ref T value, U container, string file = __FILE__, size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T))
{
    import std.algorithm: find;
    import std.array: empty;
    assert_(!find(container, value).empty, file, line);
}

/// Assert value is not in container.
void shouldNotBeIn(T, U)(const scope auto ref T value, const scope auto ref U container, string file = __FILE__, size_t line = __LINE__)
    if(isLikeAssociativeArray!U) {
    assert_(!cast(bool)(value in container), file, line);
}

/// ditto.
void shouldNotBeIn(T, U)(const scope auto ref T value, U container, string file = __FILE__, size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T))
{
    import std.algorithm: find;
    import std.array: empty;
    assert_(find(container, value).empty, file, line);
}

/// Assert that expr throws.
void shouldThrow(T : Throwable = Exception, E)
                (lazy E expr, string file = __FILE__, size_t line = __LINE__) {
    import std.traits: isSafe, isUnsafe;

    auto threw = false;

    static if(isUnsafe!expr)
        void callExpr() @system { expr(); }
    else
        void callExpr() @safe   { expr(); }

    bool impl() {
        try {
            callExpr;
            return false;
        } catch(T _) {
            return true;
        }
    }

    static if(isSafe!callExpr)
        threw = () @trusted { return impl; }();
    else
        threw = impl;

    assert_(threw, file, line);
}

/// Assert that expr throws an Exception that must have the type E, derived types won't do.
void shouldThrowExactly(T : Throwable = Exception, E)
                       (lazy E expr, string file = __FILE__, size_t line = __LINE__)
{
    import std.traits: isSafe, isUnsafe;

    T throwable = null;

    static if(isUnsafe!expr)
        void callExpr() @system { expr(); }
    else
        void callExpr() @safe   { expr(); }

    void impl() {
        try
            callExpr;
        catch(T t) {
            throwable = t;
        }
    }

    static if(isSafe!callExpr)
        () @trusted { return impl; }();
    else
        impl;

    //Object.opEquals is @system and impure
    const sameType = () @trusted { return throwable !is null && typeid(throwable) == typeid(T); }();
    assert_(sameType, file, line);
}


/// Assert that expr doesn't throw
void shouldNotThrow(T: Throwable = Exception, E)
                   (lazy E expr, string file = __FILE__, size_t line = __LINE__) {

    import std.traits: isSafe, isUnsafe;

    static if(isUnsafe!expr)
        void callExpr() @system { expr(); }
    else
        void callExpr() @safe   { expr(); }

    void impl() {
        try
            callExpr;
        catch(T t) {
            assert_(false, file, line);
        }
    }

    static if(isSafe!callExpr)
        () @trusted { return impl; }();
    else
        impl;
}

/// Assert that expr throws and the exception message is msg.
void shouldThrowWithMessage(T : Throwable = Exception, E)(lazy E expr,
                                                          string msg,
                                                          string file = __FILE__,
                                                          size_t line = __LINE__) {
    import std.traits: isSafe, isUnsafe;

    T throwable = null;

    static if(isUnsafe!expr)
        void callExpr() @system { expr(); }
    else
        void callExpr() @safe   { expr(); }

    void impl() {
        try
            callExpr;
        catch(T t) {
            throwable = t;
        }
    }

    static if(isSafe!callExpr)
        () @trusted { return impl; }();
    else
        impl;

    assert_(throwable !is null && throwable.msg == msg, file, line);
}

/// Assert that value is approximately equal to expected.
void shouldApproxEqual(V, E)
                      (in V value, in E expected, double maxRelDiff = 1e-2, double maxAbsDiff = 1e-5, string file = __FILE__, size_t line = __LINE__)
{
    import std.math: approxEqual;
    assert_(approxEqual(value, expected, maxRelDiff, maxAbsDiff), file, line);
}

/// assert that rng is empty.
void shouldBeEmpty(R)(const scope auto ref R rng, string file = __FILE__, size_t line = __LINE__) {
    import std.range: isInputRange;
    import std.traits: isAssociativeArray;
    import std.array;

    static if(isInputRange!R)
        assert_(rng.empty, file, line);
    else static if(isAssociativeArray!R)
        () @trusted { assert_(rng.keys.empty, file, line); }();
    else
        static assert(false, "Cannot call shouldBeEmpty on " ~ R.stringof);
}

/// Assert that rng is not empty.
void shouldNotBeEmpty(R)(const scope auto ref R rng, string file = __FILE__, size_t line = __LINE__) {
    import std.range: isInputRange;
    import std.traits: isAssociativeArray;
    import std.array;

    static if(isInputRange!R)
        assert_(!rnd.empty, file, line);
    else static if(isAssociativeArray!R)
        () @trusted { assert_(!rng.keys.empty, file, line); }();
    else
        static assert(false, "Cannot call shouldBeEmpty on " ~ R.stringof);
}

/// Assert that t should be greater than u.
void shouldBeGreaterThan(T, U)(const scope auto ref T t, const scope auto ref U u,
                               string file = __FILE__, size_t line = __LINE__)
{
    assert_(t > u, file, line);
}

/// Assert that t should be smaller than u.
void shouldBeSmallerThan(T, U)(const scope auto ref T t, const scope auto ref U u,
                               string file = __FILE__, size_t line = __LINE__)
{
    assert_(t < u, file, line);
}

/// Assert that value is the same set as expected (i.e. order doesn't matter)
void shouldBeSameSetAs(V, E)(const scope auto ref V value, const scope auto ref E expected, string file = __FILE__, size_t line = __LINE__) {
    assert_(isSameSet(value, expected), file, line);
}

/// Assert that value is not the same set as expected.
void shouldNotBeSameSetAs(V, E)(const scope auto ref V value, const scope auto ref E expected, string file = __FILE__, size_t line = __LINE__) {
    assert_(!isSameSet(value, expected), file, line);
}

private bool isSameSet(T, U)(const scope auto ref T t, const scope auto ref U u) {
    import std.array: array;
    import std.algorithm: canFind;

    //sort makes the element types have to implement opCmp
    //instead, try one by one
    auto ta = t.array;
    auto ua = u.array;
    if (ta.length != ua.length) return false;
    foreach(element; ta)
    {
        if (!ua.canFind(element)) return false;
    }

    return true;
}

/// Assert that actual and expected represent the same JSON (i.e. formatting doesn't matter)
void shouldBeSameJsonAs(in string actual,
                        in string expected,
                        string file = __FILE__,
                        size_t line = __LINE__)
    @trusted // not @safe pure due to parseJSON
{
    import std.json: parseJSON, JSONException;

    auto parse(in string str) {
        try
            return str.parseJSON;
        catch(JSONException ex) {
            assert_(false, "Failed to parse " ~ str, file, line);
        }
        assert(0);
    }

    assert_(parse(actual) == parse(expected), file, line);
}


private void assert_(in bool value, string file, size_t line) @safe pure {
    assert_(value, "Assertion failure", file, line);
}

private void assert_(bool value, string message, string file, size_t line) @safe pure {
    if(!value)
        throw new Exception(message, file, line);
}

void fail(in string output, string file, size_t line) @safe pure {
    assert_(false, output, file, line);
}


auto should(E)(lazy E expr) {

    struct Should {

        bool opEquals(U)(auto ref U other,
                         string file = __FILE__,
                         size_t line = __LINE__)
        {
            expr.shouldEqual(other, file, line);
            return true;
        }
    }

    return Should();
}
