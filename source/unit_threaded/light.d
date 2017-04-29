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


int runTests(T...)(in string[] args) {

    import core.runtime: Runtime;
    import core.stdc.stdio: printf;

    try {

        Runtime.moduleUnitTester();

        printf("\n");
        version(Posix)
            printf("\033[32;1mOk\033[0;;m");
        else
            printf("Ok");

        printf(": All tests passed\n\n");

        return 0;
    } catch(Throwable _)
        return 1;
}

void writelnUt(T...)(auto ref T args) {

}

void check(alias F)(int numFuncCalls = 100,
                    in string file = __FILE__, in size_t line = __LINE__) @trusted {
    import unit_threaded.property: utCheck = check;
    utCheck!F(numFuncCalls, file, line);
}

void checkCustom(alias Generator, alias Predicate)
                (int numFuncCalls = 100, in string file = __FILE__, in size_t line = __LINE__) @trusted {
    import unit_threaded.property: utCheckCustom = checkCustom;
    utCheckCustom!(Generator, Predicate)(numFuncCalls, file, line);
}


interface Output {
    void send(in string output) @safe;
    void flush() @safe;
}

class TestCase {
    abstract void test();
    void setup() {}
    void shutdown() {}
    static TestCase currentTest() { return new class TestCase { override void test() {}}; }
    Output getWriter() { return new class Output { override void send(in string output) {} override void flush() {}}; }
}


auto mock(T)() {
    import unit_threaded.mock: utMock = mock;
    return utMock!T;
}

auto mockStruct(T...)(auto ref T returns) {
    import unit_threaded.mock: utMockStruct = mockStruct;
    return utMockStruct(returns);
}

void shouldBeTrue(E)(lazy E condition, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(cast(bool)condition(), file, line);
}

void shouldBeFalse(E)(lazy E condition, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(!cast(bool)condition(), file, line);
}

void shouldEqual(V, E)(auto ref V value, auto ref E expected, in string file = __FILE__, in size_t line = __LINE__) {

    void checkInputRange(T)(auto ref const(T) _) @trusted {
        auto obj = cast(T)_;
        bool e = obj.empty;
        auto f = obj.front;
        obj.popFront;
    }
    enum isInputRange(T) = is(T: Elt[], Elt) || is(typeof(checkInputRange(T.init)));

    static if(is(V == class)) {
        assert_(value.tupleof == expected.tupleof, file, line);
    } else static if(isInputRange!V && isInputRange!E) {
        auto ref unqual(T)(auto ref const(T) obj) @trusted {
            static if(is(T == void[]))
                return cast(ubyte[])obj;
            else
                return cast(T)obj;
        }
        import std.algorithm: equal;
        assert_(equal(unqual(value), unqual(expected)), file, line);
    } else {
        assert_(cast(const)value == cast(const)expected, file, line);
    }
}

void shouldNotEqual(V, E)(in auto ref V value, in auto ref E expected, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(value != expected, file, line);
}

void shouldBeNull(T)(in auto ref T value, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(value is null, file, line);
}

void shouldNotBeNull(T)(in auto ref T value, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(value !is null, file, line);
}

enum isLikeAssociativeArray(T, K) = is(typeof({
    if(K.init in T) { }
    if(K.init !in T) { }
}));
static assert(isLikeAssociativeArray!(string[string], string));
static assert(!isLikeAssociativeArray!(string[string], int));


void shouldBeIn(T, U)(in auto ref T value, in auto ref U container, in string file = __FILE__, in size_t line = __LINE__)
    if(isLikeAssociativeArray!U) {
    assert_(cast(bool)(value in container), file, line);
}

void shouldBeIn(T, U)(in auto ref T value, U container, in string file = __FILE__, in size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T))
{
    import std.algorithm: find;
    import std.array: empty;
    assert_(!find(container, value).empty, file, line);
}

void shouldNotBeIn(T, U)(in auto ref T value, in auto ref U container, in string file = __FILE__, in size_t line = __LINE__)
    if(isLikeAssociativeArray!U) {
    assert_(!cast(bool)(value in container), file, line);
}

void shouldNotBeIn(T, U)(in auto ref T value, U container, in string file = __FILE__, in size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T))
{
    import std.algorithm: find;
    import std.array: empty;
    assert_(find(container, value).empty, file, line);
}

void shouldThrow(T : Throwable = Exception, E)
                (lazy E expr, in string file = __FILE__, in size_t line = __LINE__) {
    () @trusted {
        try {
            expr();
            assert_(false, file, line);
        } catch(T _) {

        }
    }();
}

void shouldThrowExactly(T : Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in size_t line = __LINE__)
{
    () @trusted {
        try {
            expr();
            assert_(false, file, line);
        } catch(T _) {
            //Object.opEquals is @system and impure
            const sameType = () @trusted { return threw.typeInfo == typeid(T); }();
            assert_(sameType, file, line);
        }
    }();
}

void shouldNotThrow(T: Throwable = Exception, E)
                   (lazy E expr, in string file = __FILE__, in size_t line = __LINE__) {
    () @trusted {
        try
            expr();
        catch(T _)
            assert_(false, file, line);
    }();
}

void shouldThrowWithMessage(T : Throwable = Exception, E)(lazy E expr,
                                                          string msg,
                                                          string file = __FILE__,
                                                          size_t line = __LINE__) {
    () @trusted {
        try {
            expr();
            assert_(false, file, line);
        } catch(T ex) {
            assert_(ex.msg == msg, file, line);
        }
    }();
}

void shouldApproxEqual(V, E)(in V value, in E expected, string file = __FILE__, size_t line = __LINE__) {
    import std.math: approxEqual;
    assert_(approxEqual(value, expected), file, line);
}

void shouldBeEmpty(R)(in auto ref R rng, in string file = __FILE__, in size_t line = __LINE__) {
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

void shouldNotBeEmpty(R)(in auto ref R rng, in string file = __FILE__, in size_t line = __LINE__) {
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

void shouldBeGreaterThan(T, U)(in auto ref T t, in auto ref U u,
                               in string file = __FILE__, in size_t line = __LINE__)
{
    assert_(t > u, file, line);
}

void shouldBeSmallerThan(T, U)(in auto ref T t, in auto ref U u,
                               in string file = __FILE__, in size_t line = __LINE__)
{
    assert_(t < u, file, line);
}

void shouldBeSameSetAs(V, E)(in auto ref V value, in auto ref E expected, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(isSameSet(value, expected), file, line);
}

void shouldNotBeSameSetAs(V, E)(in auto ref V value, in auto ref E expected, in string file = __FILE__, in size_t line = __LINE__) {
    assert_(!isSameSet(value, expected), file, line);
}

private bool isSameSet(T, U)(in auto ref T t, in auto ref U u) {
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

void shouldBeSameJsonAs(in string actual,
                        in string expected,
                        in string file = __FILE__,
                        in size_t line = __LINE__)
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


private void assert_(in bool value, in string file, in size_t line) @safe pure {
    assert_(value, "Assertion failure", file, line);
}

private void assert_(bool value, in string message, in string file, in size_t line) @trusted pure {
    if(!value)
        throw new Exception(message, file, line);
}

void fail(in string output, in string file, in size_t line) @safe pure {
    assert_(false, output, file, line);
}
