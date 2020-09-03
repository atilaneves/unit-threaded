/**
 * This module implements custom assertions via $(D shouldXXX) functions
 * that throw exceptions containing information about why the assertion
 * failed.
 */
module unit_threaded.assertions;


import unit_threaded.exception: fail, UnitTestException;
import std.traits; // too many to list
import std.range; // also


/**
 * Verify that the condition is `true`.
 * Throws: UnitTestException on failure.
 */
void shouldBeTrue(E)(lazy E condition, string file = __FILE__, size_t line = __LINE__)
{
    shouldEqual(cast(bool)condition, true, file, line);
}

///
@safe pure unittest
{
    shouldBeTrue(true);
}


/**
 * Verify that the condition is `false`.
 * Throws: UnitTestException on failure.
 */
void shouldBeFalse(E)(lazy E condition, string file = __FILE__, size_t line = __LINE__)
{
    shouldEqual(cast(bool)condition, false, file, line);
}

///
@safe pure unittest
{
    shouldBeFalse(false);
}


/**
 * Verify that two values are the same.
 * Throws: UnitTestException on failure
 */
void shouldEqual(V, E)(scope auto ref V value, scope auto ref E expected, string file = __FILE__, size_t line = __LINE__)
{
    if (!isEqual(value, expected))
    {
        const msg = formatValueInItsOwnLine("Expected: ", expected) ~
                    formatValueInItsOwnLine("     Got: ", value);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest {
    shouldEqual(true, true);
    shouldEqual(false, false);
    shouldEqual(1, 1) ;
    shouldEqual("foo", "foo") ;
    shouldEqual([2, 3], [2, 3]) ;

    shouldEqual(iota(3), [0, 1, 2]);
    shouldEqual([[0, 1], [0, 1, 2]], [[0, 1], [0, 1, 2]]);
    shouldEqual([[0, 1], [0, 1, 2]], [iota(2), iota(3)]);
    shouldEqual([iota(2), iota(3)], [[0, 1], [0, 1, 2]]);

}


/**
 * Verify that two values are not the same.
 * Throws: UnitTestException on failure
 */
void shouldNotEqual(V, E)
                   (scope auto ref V value,
                    scope auto ref E expected,
                    string file = __FILE__,
                    size_t line = __LINE__)
{
    if (isEqual(value, expected))
    {
        const msg = ["Value:",
                     formatValueInItsOwnLine("", value).join(""),
                     "is not expected to be equal to:",
                     formatValueInItsOwnLine("", expected).join("")
            ];
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest
{
    shouldNotEqual(true, false);
    shouldNotEqual(1, 2);
    shouldNotEqual("f", "b");
    shouldNotEqual([2, 3], [2, 3, 4]);
}

///
@safe unittest {
    shouldNotEqual(1.0, 2.0);
}



/**
 * Verify that the value is null.
 * Throws: UnitTestException on failure
 */
void shouldBeNull(T)(const scope auto ref T value, string file = __FILE__, size_t line = __LINE__)
{
    if (value !is null)
        fail("Value is not null", file, line);
}

///
@safe pure unittest
{
    shouldBeNull(null);
}


/**
 * Verify that the value is not null.
 * Throws: UnitTestException on failure
 */
void shouldNotBeNull(T)(const scope auto ref T value, string file = __FILE__, size_t line = __LINE__)
{
    if (value is null)
        fail("Value is null", file, line);
}

///
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
}

enum isLikeAssociativeArray(T, K) = is(typeof({
    if(K.init in T) { }
    if(K.init !in T) { }
}));

static assert(isLikeAssociativeArray!(string[string], string));
static assert(!isLikeAssociativeArray!(string[string], int));


/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
*/
void shouldBeIn(T, U)(const scope auto ref T value, const scope auto ref U container, string file = __FILE__, size_t line = __LINE__)
    if (isLikeAssociativeArray!(U, T))
{
    import std.conv: to;

    if (value !in container)
    {
        fail(formatValueInItsOwnLine("Value ", value) ~ formatValueInItsOwnLine("not in ", container),
             file, line);
    }
}

///
@safe pure unittest {
    5.shouldBeIn([5: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldBeIn(AA(5));
}

/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
 */
void shouldBeIn(T, U)(const scope auto ref T value, U container, string file = __FILE__, size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T) && isInputRange!U)
{
    import std.algorithm: find;
    import std.conv: to;

    if (find(container, value).empty)
    {
        fail(formatValueInItsOwnLine("Value ", value) ~ formatValueInItsOwnLine("not in ", container),
             file, line);
    }
}

///
@safe pure unittest
{
    shouldBeIn(4, [1, 2, 4]);
    shouldBeIn("foo", ["foo" : 1]);
}


/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(const scope auto ref T value, const scope auto ref U container,
                         string file = __FILE__, size_t line = __LINE__)
    if (isLikeAssociativeArray!(U, T))
{
    import std.conv: to;

    if (value in container)
    {
        fail(formatValueInItsOwnLine("Value ", value) ~ formatValueInItsOwnLine("is in ", container),
             file, line);
    }
}

///
@safe pure unittest {
    5.shouldNotBeIn([4: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldNotBeIn(AA(4));
}


/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(const scope auto ref T value, U container,
                         string file = __FILE__, size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T) && isInputRange!U)
{
    import std.algorithm: find;
    import std.conv: to;

    if (!find(container, value).empty)
    {
        fail(formatValueInItsOwnLine("Value ", value) ~ formatValueInItsOwnLine("is in ", container),
             file, line);
    }
}

///
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
                return array.empty;
            }
        }
        return ArrayRangeWithoutLength!T(array);
    }

    shouldNotBeIn(3.5, [1.1, 2.2, 4.4]);
    shouldNotBeIn(1.0, [2.0 : 1, 3.0 : 2]);
    shouldNotBeIn(1, arrayRangeWithoutLength([2, 3, 4]));
}

private struct ThrownInfo
{
    TypeInfo typeInfo;
    string msg;
}

/**
 * Verify that expr throws the templated Exception class.
 * This succeeds if the expression throws a child class of
 * the template parameter.
 * Returns: A `ThrownInfo` containing info about the throwable
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
auto shouldThrow(T : Throwable = Exception, E)
                (lazy E expr, string file = __FILE__, size_t line = __LINE__)
{
    import std.conv: text;

    // separate in order to not be inside the @trusted
    auto callThrew() { return threw!T(expr); }
    void wrongThrowableType(scope Throwable t) {
        fail(text("Expression threw ", typeid(t), " instead of the expected ", T.stringof, ":\n", t.msg), file, line);
    }
    void didntThrow() { fail("Expression did not throw", file, line); }

    // insert dummy call outside @trusted to correctly infer the attributes of shouldThrow
    if (false) {
        callThrew();
        wrongThrowableType(null);
        didntThrow();
    }

    return () @trusted { // @trusted because of catching Throwable
        try {
            const result = callThrew();
            if (result.threw)
                return result.info;
        }
        catch(Throwable t)
            wrongThrowableType(t);
        didntThrow();
        assert(0);
    }();
}

///
@safe pure unittest {
    void funcThrows(string msg) { throw new Exception(msg); }
    try {
        auto exceptionInfo = funcThrows("foo bar").shouldThrow;
        assert(exceptionInfo.msg == "foo bar");
    } catch(Exception e) {
        assert(false, "should not have thrown anything and threw: " ~ e.msg);
    }
}

///
@safe pure unittest {
    void func() {}
    try {
        func.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assert(e.msg == "Expression did not throw");
}

///
@safe pure unittest {
    void funcAsserts() { assert(false, "Oh noes"); }
    try {
        funcAsserts.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assert(e.msg ==
               "Expression threw core.exception.AssertError instead of the expected Exception:\nOh noes");
}


/**
 * Verify that expr throws the templated Exception class.
 * This only succeeds if the expression throws an exception of
 * the exact type of the template parameter.
 * Returns: A `ThrownInfo` containing info about the throwable
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
auto shouldThrowExactly(T : Throwable = Exception, E)(lazy E expr,
    string file = __FILE__, size_t line = __LINE__)
{
    import std.conv: text;

    const threw = threw!T(expr);
    if (!threw.threw)
        fail("Expression did not throw", file, line);

    //Object.opEquals is @system and impure
    const sameType = () @trusted { return threw.info.typeInfo == typeid(T); }();
    if (!sameType)
        fail(text("Expression threw wrong type ", threw.info.typeInfo,
            "instead of expected type ", typeid(T)), file, line);

    return threw.info;
}

/**
 * Verify that expr does not throw the templated Exception class.
 * Throws: UnitTestException on failure
 */
void shouldNotThrow(T: Throwable = Exception, E)(lazy E expr,
    string file = __FILE__, size_t line = __LINE__)
{
    if (threw!T(expr).threw)
        fail("Expression threw", file, line);
}


/**
 * Verify that an exception is thrown with the right message
 */
void shouldThrowWithMessage(T : Throwable = Exception, E)(lazy E expr,
                                                          string msg,
                                                          string file = __FILE__,
                                                          size_t line = __LINE__) {
    auto threw = threw!T(expr);

    if (!threw.threw)
        fail("Expression did not throw", file, line);

    threw.info.msg.shouldEqual(msg, file, line);
}

///
@safe pure unittest {
    void funcThrows(string msg) { throw new Exception(msg); }
    funcThrows("foo bar").shouldThrowWithMessage!Exception("foo bar");
    funcThrows("foo bar").shouldThrowWithMessage("foo bar");
}

private auto threw(T : Throwable, E)(lazy E expr)
{
    import std.typecons : tuple;
    import std.array: array;
    import std.conv: text;
    import std.traits: isSafe, isUnsafe;

    auto ret = tuple!("threw", "info")(false, ThrownInfo.init);

    // separate in order to not be inside the @trusted
    auto makeRet(scope T e) {
        // the message might have to be copied because of lifetime issues
        // .msg is sometimes a range, so .array
        // but .array sometimes returns dchar[] (autodecoding), so .text
        return tuple!("threw", "info")(true, ThrownInfo(typeid(e), e.msg.array.dup.text));
    }

    static if(isUnsafe!expr)
        void callExpr() @system { expr(); }
    else
        void callExpr() @safe   { expr(); }

    auto impl() {
        try {
            callExpr;
            return tuple!("threw", "info")(false, ThrownInfo.init);
        }
        catch(T t) {
            return makeRet(t);
        }
    }

    static if(isSafe!callExpr && isSafe!makeRet)
        return () @trusted { return impl; }();
    else
        return impl;
}


// Formats output in different lines
private string[] formatValueInItsOwnLine(T)(in string prefix, scope auto ref T value) {

    import std.conv: to;
    import std.traits: isSomeString;
    import std.range.primitives: isInputRange;

    static if(isSomeString!T) {
        // isSomeString is true for wstring and dstring,
        // so call .to!string anyway
        return [ prefix ~ `"` ~ value.to!string ~ `"`];
    } else static if(isInputRange!T) {
        return formatRange(prefix, value);
    } else {
        return [prefix ~ convertToString(value)];
    }
}

// helper function for non-copyable types
string convertToString(T)(scope auto ref T value) {  // std.conv.to sometimes is @system
    import std.conv: text, to;
    import std.traits: isFloatingPoint, isAssociativeArray;
    import std.format: format;

    static string text_(scope ref const(T) value) {
        static if(isAssociativeArray!T)
            return (scope ref const(T) value) @trusted { return value.text; }(value);
        else static if(__traits(compiles, value.text))
            return text(value);
        else static if(__traits(compiles, value.to!string))
            return value.to!string;
    }

    static if(isFloatingPoint!T)
        return format!"%.6f"(value);
    else static if(__traits(compiles, text_(value)))
        return text_(value);
    else static if(__traits(compiles, value.toString))
        return value.toString;
    else
        return T.stringof ~ "<cannot print>";
}


private string[] formatRange(T)(in string prefix, scope auto ref T value) {
    import std.conv: text;
    import std.range: ElementType;
    import std.algorithm: map, reduce, max;

    //some versions of `text` are @system
    auto defaultLines = () @trusted { return [prefix ~ value.text]; }();

    static if (!isInputRange!(ElementType!T))
        return defaultLines;
    else
    {
        import std.array: array;
        const maxElementSize = value.empty ? 0 : value.map!(a => a.array.length).reduce!max;
        const tooBigForOneLine = (value.array.length > 5 && maxElementSize > 5) || maxElementSize > 10;
        if (!tooBigForOneLine)
            return defaultLines;
        return [prefix ~ "["] ~
            value.map!(a => formatValueInItsOwnLine("              ", a).join("") ~ ",").array ~
            "          ]";
    }
}

private enum isObject(T) = is(T == class) || is(T == interface);

bool isEqual(V, E)(auto ref V value, auto ref E expected)
 if (!isObject!V && !isInputRange!V &&
     is(typeof(value == expected) == bool))
{
    return value == expected;
}


// The reason this overload exists is because for some reason we can't
// compare a mutable AA with a const one so we force both of them to
// be const here, while not forcing users to have a const opEquals
// in their own types
bool isEqual(V, E)(in V value, in E expected)
    if (isAssociativeArray!V && isAssociativeArray!E)
{
    return value == expected;
}


/**
 * Verify that two floating point values are approximately equal
 * Params:
 *    value = the value to check.
 *    expected = the expected value
 *    maxRelDiff = the maximum relative difference
 *    maxAbsDiff = the maximum absolute difference
 * Throws: UnitTestException on failure
 */
void shouldApproxEqual(V, E)
                      (in V value,
                       in E expected,
                       double maxRelDiff = 1e-2,
                       double maxAbsDiff = 1e-5,
                       string file = __FILE__,
                       size_t line = __LINE__)
 if ((isFloatingPoint!V || isFloatingPoint!E) && is(typeof(value == expected) == bool))
{
    import std.math: approxEqual;
    if (!approxEqual(value, expected, maxRelDiff, maxAbsDiff))
    {
        const msg =
            formatValueInItsOwnLine("Expected approx: ", expected) ~
            formatValueInItsOwnLine("     Got       : ", value);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe unittest {
    1.0.shouldApproxEqual(1.0001);
}


bool isEqual(V, E)(scope V value, scope E expected)
    if(isInputRange!V && isStaticArray!E)
{
    return isEqual(value, expected[]);
}


bool isEqual(V, E)(scope V value, scope E expected)
    if (isInputRange!V && isInputRange!E && !isSomeString!V &&
        is(typeof(isEqual(value.front, expected.front))))
{

    while (!value.empty && !expected.empty) {
        if(!isEqual(value.front, expected.front)) return false;
        value.popFront;
        expected.popFront;
    }

    return value.empty && expected.empty;
}

bool isEqual(V, E)(scope V value, scope E expected)
    if (isSomeString!V && isSomeString!E &&
        is(typeof(isEqual(value.front, expected.front))))
{
    if(value.length != expected.length) return false;
    // prevent auto-decoding
    foreach(i; 0 .. value.length)
        if(value[i] != expected[i]) return false;

    return true;
}

template IsField(A...) if(A.length == 1) {
    enum IsField = __traits(compiles, A[0].init);
}


bool isEqual(V, E)(scope V value, scope E expected)
    if (isObject!V && isObject!E)
{
    import std.meta: staticMap, Filter, staticIndexOf;

    static assert(is(typeof(() { string s1 = value.toString; string s2 = expected.toString;})),
                  "Cannot compare instances of " ~ V.stringof ~
                  " or " ~ E.stringof ~ " unless toString is overridden for both");

    if(value  is null && expected !is null) return false;
    if(value !is null && expected  is null) return false;
    if(value  is null && expected  is null) return true;

    // If it has opEquals, use it
    static if(staticIndexOf!("opEquals", __traits(derivedMembers, V)) != -1) {
        return value.opEquals(expected);
    } else {

        template IsFieldOf(T, string s) {
            static if(__traits(compiles, IsField!(typeof(__traits(getMember, T.init, s)))))
                enum IsFieldOf = IsField!(typeof(__traits(getMember, T.init, s)));
            else
                enum IsFieldOf = false;
        }

        auto members(T)(T obj) {
            import std.typecons: Tuple;
            import std.meta: staticMap;
            import std.traits: Unqual;

            alias Member(string name) = typeof(__traits(getMember, T, name));
            alias IsFieldOfT(string s) = IsFieldOf!(T, s);
            alias FieldNames = Filter!(IsFieldOfT, __traits(allMembers, T));
            alias FieldTypes = staticMap!(Member, FieldNames);

            Tuple!(staticMap!(Unqual, FieldTypes)) ret;
            foreach(i, name; FieldNames)
                ret[i] = __traits(getMember, obj, name);

            return ret;
        }

        static if(is(V == interface))
            return false;
        else
            return members(value) == members(expected);
    }
}


/**
 * Verify that rng is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(R)(const scope auto ref R rng, string file = __FILE__, size_t line = __LINE__)
if (isInputRange!R)
{
    import std.conv: text;
    if (!rng.empty)
        fail(text("Range not empty: ", rng), file, line);
}

/**
 * Verify that rng is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(R)(auto ref shared(R) rng, string file = __FILE__, size_t line = __LINE__)
if (isInputRange!R)
{
    import std.conv: text;
    if (!rng.empty)
        fail(text("Range not empty: ", rng), file, line);
}


/**
 * Verify that aa is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(T)(auto ref T aa, string file = __FILE__, size_t line = __LINE__)
if (isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (!aa.keys.empty) fail("AA not empty", file, line); }();
}

///
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
}


/**
 * Verify that rng is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(R)(R rng, string file = __FILE__, size_t line = __LINE__)
if (isInputRange!R)
{
    if (rng.empty)
        fail("Range empty", file, line);
}

/**
 * Verify that aa is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(T)(const scope auto ref T aa, string file = __FILE__, size_t line = __LINE__)
if (isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (aa.keys.empty)
        fail("AA empty", file, line); }();
}

///
@safe pure unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    shouldNotBeEmpty(ints);
    shouldNotBeEmpty(strings);
    shouldNotBeEmpty(aa);
}

/**
 * Verify that t is greater than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeGreaterThan(T, U)(const scope auto ref T t, const scope auto ref U u,
                               string file = __FILE__, size_t line = __LINE__)
{
    import std.conv: text;
    if (t <= u)
        fail(text(t, " is not > ", u), file, line);
}

///
@safe pure unittest
{
    shouldBeGreaterThan(7, 5);
}


/**
 * Verify that t is smaller than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeSmallerThan(T, U)(const scope auto ref T t, const scope auto ref U u,
                               string file = __FILE__, size_t line = __LINE__)
{
    import std.conv: text;
    if (t >= u)
        fail(text(t, " is not < ", u), file, line);
}

///
@safe pure unittest
{
    shouldBeSmallerThan(5, 7);
}



/**
 * Verify that t and u represent the same set (ordering is not important).
 * Throws: UnitTestException on failure.
 */
void shouldBeSameSetAs(V, E)(auto ref V value, auto ref E expected, string file = __FILE__, size_t line = __LINE__)
if (isInputRange!V && isInputRange!E && is(typeof(value.front != expected.front) == bool))
{
    import std.algorithm: sort;
    import std.array: array;

    if (!isSameSet(value, expected))
    {
        static if(__traits(compiles, sort(expected.array)))
            const expPrintRange = sort(expected.array).array;
        else
            alias expPrintRange = expected;

        static if(__traits(compiles, sort(value.array)))
            const actPrintRange = sort(value.array).array;
        else
            alias actPrintRange = value;

        const msg = formatValueInItsOwnLine("Expected: ", expPrintRange) ~
                    formatValueInItsOwnLine("     Got: ", actPrintRange);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest
{
    import std.range: iota;

    auto inOrder = iota(4);
    auto noOrder = [2, 3, 0, 1];
    auto oops = [2, 3, 4, 5];

    inOrder.shouldBeSameSetAs(noOrder);
    inOrder.shouldBeSameSetAs(oops).shouldThrow!UnitTestException;

    struct Struct
    {
        int i;
    }

    [Struct(1), Struct(4)].shouldBeSameSetAs([Struct(4), Struct(1)]);
}

private bool isSameSet(T, U)(auto ref T t, auto ref U u) {
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

/**
 * Verify that value and expected do not represent the same set (ordering is not important).
 * Throws: UnitTestException on failure.
 */
void shouldNotBeSameSetAs(V, E)(auto ref V value, auto ref E expected, string file = __FILE__, size_t line = __LINE__)
if (isInputRange!V && isInputRange!E && is(typeof(value.front != expected.front) == bool))
{
    if (isSameSet(value, expected))
    {
        const msg = ["Value:",
                     formatValueInItsOwnLine("", value).join(""),
                     "is not expected to be equal to:",
                     formatValueInItsOwnLine("", expected).join("")
            ];
        throw new UnitTestException(msg, file, line);
    }
}


///
@safe pure unittest
{
    auto inOrder = iota(4);
    auto noOrder = [2, 3, 0, 1];
    auto oops = [2, 3, 4, 5];

    inOrder.shouldNotBeSameSetAs(oops);
    inOrder.shouldNotBeSameSetAs(noOrder).shouldThrow!UnitTestException;
}




/**
   If two strings represent the same JSON regardless of formatting
 */
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
        catch(JSONException ex)
            throw new UnitTestException("Error parsing JSON: " ~ ex.msg, file, line);
    }

    parse(actual).toPrettyString.shouldEqual(parse(expected).toPrettyString, file, line);
}

///
@safe unittest { // not pure because parseJSON isn't pure
    `{"foo": "bar"}`.shouldBeSameJsonAs(`{"foo": "bar"}`);
    `{"foo":    "bar"}`.shouldBeSameJsonAs(`{"foo":"bar"}`);
    `{"foo":"bar"}`.shouldBeSameJsonAs(`{"foo": "baz"}`).shouldThrow!UnitTestException;
    try
        `oops`.shouldBeSameJsonAs(`oops`);
    catch(Exception e)
        assert(e.msg == "Error parsing JSON: Unexpected character 'o'. (Line 1:1)");
}



auto should(V)(scope auto ref V value){

    import std.functional: forward;

    struct ShouldNot {

        bool opEquals(U)(auto ref U other,
                         string file = __FILE__,
                         size_t line = __LINE__)
        {
            shouldNotEqual(forward!value, other, file, line);
            return true;
        }

        void opBinary(string op, R)(R range,
                                    string file = __FILE__,
                                    size_t line = __LINE__) const if(op == "in") {
            shouldNotBeIn(forward!value, range, file, line);
        }

        void opBinary(string op, R)(R expected,
                                    string file = __FILE__,
                                    size_t line = __LINE__) const
            if(op == "~" && isInputRange!R)
        {
            import std.conv: text;

            bool failed;

            try
                shouldBeSameSetAs(forward!value, expected);
            catch(UnitTestException)
                failed = true;

            if(!failed)
                fail(text(value, " should not be the same set as ", expected),
                     file, line);
        }

        void opBinary(string op, E)
                     (in E expected, string file = __FILE__, size_t line = __LINE__)
            if (isFloatingPoint!E)
        {
            import std.conv: text;

            bool failed;

            try
                shouldApproxEqual(forward!value, expected);
            catch(UnitTestException)
                failed = true;

            if(!failed)
                fail(text(value, " should not be approximately equal to ", expected),
                     file, line);
        }
    }

    struct Should {

        bool opEquals(U)(auto ref U other,
                         string file = __FILE__,
                         size_t line = __LINE__)
        {
            shouldEqual(forward!value, other, file, line);
            return true;
        }

        void opBinary(string op, R)(R range,
                                    string file = __FILE__,
                                    size_t line = __LINE__) const
            if(op == "in")
        {
            shouldBeIn(forward!value, range, file, line);
        }

        void opBinary(string op, R)(R range,
                                    string file = __FILE__,
                                    size_t line = __LINE__) const
            if(op == "~" && isInputRange!R)
        {
            shouldBeSameSetAs(forward!value, range, file, line);
        }

        void opBinary(string op, E)
                     (in E expected, string file = __FILE__, size_t line = __LINE__)
            if (isFloatingPoint!E)
        {
            shouldApproxEqual(forward!value, expected, 1e-2, 1e-5, file, line);
        }

        auto not() {
            return ShouldNot();
        }
    }

    return Should();
}



T be(T)(T sh) {
    return sh;
}

///
@safe pure unittest {
    1.should.be == 1;
    1.should.not.be == 2;
    1.should.be in [1, 2, 3];
    4.should.not.be in [1, 2, 3];
}


/**
   Asserts that `lowerBound` <= `actual` < `upperBound`
 */
void shouldBeBetween(A, L, U)
    (auto ref A actual,
     auto ref L lowerBound,
     auto ref U upperBound,
     string file = __FILE__,
     size_t line = __LINE__)
{
    import std.conv: text;
    if(actual < lowerBound || actual >= upperBound)
        fail(text(actual, " is not between ", lowerBound, " and ", upperBound), file, line);
}
