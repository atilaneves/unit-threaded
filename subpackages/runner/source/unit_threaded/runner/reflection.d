/**
   Compile-time reflection to find unit tests and set their properties.
 */
module unit_threaded.runner.reflection;


import unit_threaded.from;

/*
   These standard library imports contain something important for the code below.
   Unfortunately I don't know what they are so they're to prevent breakage.
 */
import std.traits;
import std.algorithm;
import std.array;


/**
   An alternative to writing test functions by hand to avoid compile-time
   performance penalties by using -unittest.
 */
mixin template Test(string testName, alias Body, size_t line = __LINE__) {
    import std.format: format;
    import unit_threaded.runner.attrs: Name, UnitTest;
    import unit_threaded.runner.reflection: unittestFunctionName;

    enum unitTestCode = q{
        @UnitTest
        @Name("%s")
        void %s() {

        }
    }.format(testName, unittestFunctionName(line));

    //pragma(msg, unitTestCode);
    mixin(unitTestCode);
}


string unittestFunctionName(size_t line = __LINE__) {
    import std.conv: text;
    return "unittest_L" ~ line.text;
}

///
alias TestFunction = void delegate();

/**
 * Common data for test functions and test classes
 */
struct TestData {
    string name;
    TestFunction testFunction; ///only used for functions, null for classes
    bool hidden;
    bool shouldFail;
    bool singleThreaded;
    bool builtin;
    string suffix; // append to end of getPath
    string[] tags;
    TypeInfo exceptionTypeInfo; // for ShouldFailWith
    int flakyRetries = 0;

    /// The test's name
    string getPath() const pure nothrow {
        string path = name.dup;
        import std.array: empty;
        if(!suffix.empty) path ~= "." ~ suffix;
        return path;
    }

    /// If the test is a class
    bool isTestClass() @safe const pure nothrow {
        return testFunction is null;
    }
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module strings
 */
const(TestData)[] allTestData(MOD_STRINGS...)()
    if(from!"std.meta".allSatisfy!(from!"std.traits".isSomeString, typeof(MOD_STRINGS)))
{
    import std.array: join;
    import std.range : iota;
    import std.format : format;
    import std.algorithm : map;

    string getModulesString() {
        string[] modules;
        foreach(i, module_; MOD_STRINGS) modules ~= "module%d = %s".format(i, module_);
        return modules.join(", ");
    }

    enum modulesString = getModulesString;
    mixin("import " ~ modulesString ~ ";");
    mixin("return allTestData!(" ~
          MOD_STRINGS.length.iota.map!(i => "module%d".format(i)).join(", ") ~
          ");");
}


/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module symbols
 */
const(TestData)[] allTestData(MOD_SYMBOLS...)()
    if(!from!"std.meta".anySatisfy!(from!"std.traits".isSomeString, typeof(MOD_SYMBOLS)))
{
    return
        moduleTestClasses!MOD_SYMBOLS ~
        moduleTestFunctions!MOD_SYMBOLS ~
        moduleUnitTests!MOD_SYMBOLS;
}


private template Identity(T...) if(T.length > 0) {
    static if(__traits(compiles, { alias x = T[0]; }))
        alias Identity = T[0];
    else
        enum Identity = T[0];
}


/**
   Names a test function / built-in unittest based on @Name or string UDAs
   on it. If none are found, "returns" an empty string
 */
template TestNameFromAttr(alias testFunction) {
    import unit_threaded.runner.attrs: Name;
    import std.traits: getUDAs;
    import std.meta: Filter;

    // i.e. if @("this is my name") appears
    enum strAttrs = Filter!(isStringUDA, __traits(getAttributes, testFunction));

    enum nameAttrs = getUDAs!(testFunction, Name);
    static assert(nameAttrs.length < 2, "Only one @Name UDA allowed");

    // strAttrs might be values to pass so only if the length is 1 is it a name
    enum hasName = nameAttrs.length || strAttrs.length == 1;

    static if(hasName) {
        static if(nameAttrs.length == 1)
            enum TestNameFromAttr = nameAttrs[0].value;
        else
            enum TestNameFromAttr = strAttrs[0];
    } else
        enum TestNameFromAttr = "";
}

/**
 * Finds all built-in unittest blocks in the given modules.
 * Recurses into structs, classes, and unions of the modules.
 *
 * @return An array of TestData structs
 */
TestData[] moduleUnitTests(modules...)() {
    TestData[] ret;
    static foreach(module_; modules) {
        ret ~= moduleUnitTests_!module_;
    }
    return ret;
}

/**
 * Finds all built-in unittest blocks in the given module.
 * Recurses into structs, classes, and unions of the module.
 *
 * @return An array of TestData structs
 */
private TestData[] moduleUnitTests_(alias module_)() {

    // Return a name for a unittest block. If no @Name UDA is found a name is
    // created automatically, else the UDA is used.
    // the weird name for the first template parameter is so that it doesn't clash
    // with a package name
    string unittestName(alias _theUnitTest, int index)() @safe nothrow {
        import std.conv: text;
        import std.algorithm: startsWith, endsWith;
        import std.traits: fullyQualifiedName;

        enum prefix = fullyQualifiedName!(__traits(parent, _theUnitTest)) ~ ".";
        enum nameFromAttr = TestNameFromAttr!_theUnitTest;

        // Establish a unique name for a unittest with no name
        static if(nameFromAttr == "") {
            // use the unittest name if available to allow for running unittests based
            // on location
            if(__traits(identifier, _theUnitTest).startsWith("__unittest_L")) {
                const ret = prefix ~ __traits(identifier, _theUnitTest)[2 .. $];
                const suffix = "_C1";
                // simplify names for the common case where there's only one
                // unittest per line

                return ret.endsWith(suffix) ? ret[0 .. $ - suffix.length] : ret;
            }

            try
                return prefix ~ "unittest" ~ index.text;
            catch(Exception)
                assert(false, text("Error converting ", index, " to string"));

        } else
            return prefix ~ nameFromAttr;
    }

    void function() getUDAFunction(alias composite, alias uda)() pure nothrow {
        import std.traits: isSomeFunction, hasUDA;

        void function()[] ret;
        foreach(memberStr; __traits(allMembers, composite)) {
            static if(__traits(compiles, Identity!(__traits(getMember, composite, memberStr)))) {
                alias member = Identity!(__traits(getMember, composite, memberStr));
                static if(__traits(compiles, &member)) {
                    static if(isSomeFunction!member && hasUDA!(member, uda)) {
                        ret ~= &member;
                    }
                }
            }
        }

        return ret.length ? ret[0] : null;
    }

    TestData[] testData;

    void addMemberUnittests(alias composite)() pure nothrow {

        import unit_threaded.runner.attrs;
        import std.traits: hasUDA;
        import std.meta: Filter, aliasSeqOf;
        import std.algorithm: map, cartesianProduct;

        // weird name for hygiene reasons
        foreach(index, eLtEstO; __traits(getUnitTests, composite)) {

            enum dontTest = hasUDA!(eLtEstO, DontTest);

            static if(!dontTest) {

                enum name = unittestName!(eLtEstO, index);
                enum hidden = hasUDA!(eLtEstO, HiddenTest);
                enum shouldFail = hasUDA!(eLtEstO, ShouldFail) || hasUDA!(eLtEstO, ShouldFailWith);
                enum singleThreaded = hasUDA!(eLtEstO, Serial);
                enum builtin = true;
                enum suffix = "";

                // let's check for @Values UDAs, which are actually of type ValuesImpl
                enum isValues(alias T) = is(typeof(T)) && is(typeof(T):ValuesImpl!U, U);
                alias valuesUDAs = Filter!(isValues, __traits(getAttributes, eLtEstO));

                enum isTags(alias T) = is(typeof(T)) && is(typeof(T) == Tags);
                enum tags = tagsFromAttrs!(Filter!(isTags, __traits(getAttributes, eLtEstO)));
                enum exceptionTypeInfo = getExceptionTypeInfo!eLtEstO;
                enum flakyRetries = getFlakyRetries!(eLtEstO);

                static if(valuesUDAs.length == 0) {
                    testData ~= TestData(name,
                                         () {
                                             auto setup = getUDAFunction!(composite, Setup);
                                             auto shutdown = getUDAFunction!(composite, Shutdown);

                                             if(setup) setup();
                                             scope(exit) if(shutdown) shutdown();

                                             eLtEstO();
                                         },
                                         hidden,
                                         shouldFail,
                                         singleThreaded,
                                         builtin,
                                         suffix,
                                         tags,
                                         exceptionTypeInfo,
                                         flakyRetries);
                } else {
                    import std.range;

                    // cartesianProduct doesn't work with only one range, so in the usual case
                    // of only one @Values UDA, we bind to prod with a range of tuples, just
                    // as returned by cartesianProduct.

                    static if(valuesUDAs.length == 1) {
                        import std.typecons;
                        enum prod = valuesUDAs[0].values.map!(a => tuple(a));
                    } else {
                        mixin(`enum prod = cartesianProduct(` ~ valuesUDAs.length.iota.map!
                              (a => `valuesUDAs[` ~ guaranteedToString(a) ~ `].values`).join(", ") ~ `);`);
                    }

                    foreach(comb; aliasSeqOf!prod) {
                        enum valuesName = valuesName(comb);

                        static if(hasUDA!(eLtEstO, AutoTags))
                            enum realTags = tags ~ valuesName.split(".").array;
                        else
                            enum realTags = tags;

                        testData ~= TestData(name ~ "." ~ valuesName,
                                             () {
                                                 foreach(i; aliasSeqOf!(comb.length.iota))
                                                     ValueHolder!(typeof(comb[i])).values[i] = comb[i];
                                                 eLtEstO();
                                             },
                                             hidden,
                                             shouldFail,
                                             singleThreaded,
                                             builtin,
                                             suffix,
                                             realTags,
                                             exceptionTypeInfo,
                                             flakyRetries);
                    }
                }
            }
        }
    }


    // Keeps track of mangled names of everything visited.
    bool[string] visitedMembers;

    void addUnitTestsRecursively(alias composite)() pure nothrow {

        if (composite.mangleof in visitedMembers)
            return;

        visitedMembers[composite.mangleof] = true;
        addMemberUnittests!composite();

        foreach(member; __traits(allMembers, composite)) {

            // isPrivate can't be used here. I don't know why.
            static if(__traits(compiles, __traits(getProtection, __traits(getMember, module_, member))))
                enum notPrivate = __traits(getProtection, __traits(getMember, module_, member)) != "private";
            else
                enum notPrivate = false;

            static if (
                notPrivate &&
                // If visibility of the member is deprecated, the next line still returns true
                // and yet spills deprecation warning. If deprecation is turned into error,
                // all works as intended.
                __traits(compiles, __traits(getMember, composite, member)) &&
                __traits(compiles, __traits(allMembers, __traits(getMember, composite, member))) &&
                __traits(compiles, recurse!(__traits(getMember, composite, member)))
            ) {
                recurse!(__traits(getMember, composite, member));
            }
        }
    }

    void recurse(child)() pure nothrow {
        static if (is(child == class) || is(child == struct) || is(child == union)) {
            addUnitTestsRecursively!child;
        }
    }

    addUnitTestsRecursively!module_();
    return testData;
}

private TypeInfo getExceptionTypeInfo(alias Test)() {
    import unit_threaded.runner.attrs: ShouldFailWith;
    import std.traits: hasUDA, getUDAs;

    static if(hasUDA!(Test, ShouldFailWith)) {
        alias uda = getUDAs!(Test, ShouldFailWith)[0];
        return typeid(uda.Type);
    } else
        return null;
}


private string valuesName(T)(T tuple) {
    import std.range: iota;
    import std.meta: aliasSeqOf;
    import std.array: join;

    string[] parts;
    foreach(a; aliasSeqOf!(tuple.length.iota))
        parts ~= guaranteedToString(tuple[a]);
    return parts.join(".");
}

private string guaranteedToString(T)(T value) nothrow pure @safe {
    import std.conv;
    try
        return value.to!string;
    catch(Exception ex)
        assert(0, "Could not convert value to string");
}

private string getValueAsString(T)(T value) nothrow pure @safe {
    import std.conv;
    try
        return value.to!string;
    catch(Exception ex)
        assert(0, "Could not convert value to string");
}


private template isStringUDA(alias T) {
    import std.traits: isSomeString;
    static if(__traits(compiles, isSomeString!(typeof(T))))
        enum isStringUDA = isSomeString!(typeof(T));
    else
        enum isStringUDA = false;
}

@safe pure unittest {
    static assert(isStringUDA!"foo");
    static assert(!isStringUDA!5);
}

private template isPrivate(alias module_, string moduleMember) {
    alias ut_mmbr__ = Identity!(__traits(getMember, module_, moduleMember));

    static if(__traits(compiles, __traits(getProtection, ut_mmbr__)))
        enum isPrivate = __traits(getProtection, ut_mmbr__) == "private";
    else
        enum isPrivate = true;
}


// if this member is a test function or class, given the predicate
private template PassesTestPred(alias module_, alias pred, string moduleMember) {

    static if(__traits(compiles, Identity!(__traits(getMember, module_, moduleMember)))) {

        import unit_threaded.runner.attrs: DontTest;
        import std.traits: hasUDA;

        alias member = Identity!(__traits(getMember, module_, moduleMember));

        static if(__traits(compiles, hasUDA!(member, DontTest)))
            enum hasDontTest = hasUDA!(member, DontTest);
        else
            enum hasDontTest = false;

        enum PassesTestPred =
            !isPrivate!(module_, moduleMember) &&
            pred!(module_, moduleMember) &&
            !hasDontTest;

    } else
        enum PassesTestPred = false;
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
TestData[] moduleTestClasses(modules...)() pure nothrow {

    template isTestClass(alias module_, string moduleMember) {
        import unit_threaded.runner.attrs: UnitTest;
        import std.traits: isAggregateType, hasUDA;

        alias member = Identity!(__traits(getMember, module_, moduleMember));

        static if(.isPrivate!(module_, moduleMember)) {
            enum isTestClass = false;
        } else static if(!__traits(compiles, isAggregateType!(member))) {
            enum isTestClass = false;
        } else static if(!isAggregateType!(member)) {
            enum isTestClass = false;
        } else static if(!__traits(compiles, { return new member; })) {
            enum isTestClass = false; //can't new it, can't use it
        } else {
            enum hasUnitTest = hasUDA!(member, UnitTest);
            enum hasTestMethod = __traits(hasMember, member, "test");

            enum isTestClass = is(member == class) && (hasTestMethod || hasUnitTest);
        }
    }

    TestData[] ret;

    static foreach(module_; modules) {
        ret ~= moduleTestData!(module_, isTestClass, memberTestData);
    }

    return ret;
}


/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
TestData[] moduleTestFunctions(modules...)() {

    template isTestFunction(alias module_, string moduleMember) {
        import unit_threaded.runner.attrs: UnitTest, Types;
        import std.meta: AliasSeq;
        import std.traits: isSomeFunction, hasUDA;

        alias member = Identity!(__traits(getMember, module_, moduleMember));

        static if(.isPrivate!(module_, moduleMember)) {
            enum isTestFunction = false;
        } else static if(AliasSeq!(member).length != 1) {
            enum isTestFunction = false;
        } else static if(isSomeFunction!member) {
            enum isTestFunction =
                hasTestPrefix!(module_, moduleMember) ||
                hasUDA!(member, UnitTest);
        } else static if(__traits(compiles, __traits(getAttributes, member))) {
            // in this case we handle the possibility of a template function with
            // the @Types UDA attached to it
            enum hasTestName =
                hasTestPrefix!(module_, moduleMember) ||
                hasUDA!(member, UnitTest);
            enum isTestFunction = hasTestName && hasUDA!(member, Types);
        } else {
            enum isTestFunction = false;
        }
    }

    template hasTestPrefix(alias module_, string memberName) {
        import std.uni: isUpper;

        alias member = Identity!(__traits(getMember, module_, memberName));

        enum prefix = "test";
        enum minSize = prefix.length + 1;

        static if(memberName.length >= minSize &&
                  memberName[0 .. prefix.length] == prefix &&
                  isUpper(memberName[prefix.length])) {
            enum hasTestPrefix = true;
        } else {
            enum hasTestPrefix = false;
        }
    }

    TestData[] ret;

    static foreach(module_; modules) {
        ret ~= moduleTestData!(module_, isTestFunction, createFuncTestData);
    }

    return ret;
}


/**
   Get all the test functions for this module member. There might be more than one
   when using parametrized unit tests.

   Examples:
   ------
   void testFoo() {} // -> the array contains one element, testFoo
   @(1, 2, 3) void testBar(int) {} // The array contains 3 elements, one for each UDA value
   @Types!(int, float) void testBaz(T)() {} //The array contains 2 elements, one for each type
   ------
*/
private TestData[] createFuncTestData(alias module_, string moduleMember)() {
    import unit_threaded.runner.attrs;
    import std.meta: aliasSeqOf, Alias;
    import std.traits: hasUDA;

    alias testFunction = Alias!(__traits(getMember, module_, moduleMember));

    enum isRegularFunction = __traits(compiles, &__traits(getMember, module_, moduleMember));

    static if(isRegularFunction) {

        static if(arity!testFunction == 0)
            return createRegularFuncTestData!(module_, moduleMember);
        else
            return createValueParamFuncTestData!(module_, moduleMember, testFunction);

    } else static if(hasUDA!(testFunction, Types)) { // template function with @Types
        return createTypeParamFuncTestData!(module_, moduleMember, testFunction);
    } else {
        return [];
    }
}

private TestData[] createRegularFuncTestData(alias module_, string moduleMember)() {
    import std.meta: Alias;

    alias member = Alias!(__traits(getMember, module_, moduleMember));
    enum func = &member;

    // the reason we're creating a lambda to call the function is that test functions
    // are ordinary functions, but we're storing delegates
    return [ memberTestData!member(() { func(); }) ]; //simple case, just call the function
}

// for value parameterised tests
private TestData[] createValueParamFuncTestData(alias module_, string moduleMember, alias testFunction)() {

    import unit_threaded.runner.traits: GetAttributes;
    import unit_threaded.runner.attrs: AutoTags;
    import std.traits: Parameters;
    import std.range: iota;
    import std.algorithm: map;
    import std.typecons: tuple;
    import std.traits: arity, hasUDA;
    import std.meta: aliasSeqOf, Alias;

    alias params = Parameters!testFunction;
    alias member = Alias!(__traits(getMember, module_, moduleMember));

    bool hasAttributesForAllParams() {
        auto ret = true;
        static foreach(P; params) {
            static if(GetAttributes!(member, P).length == 0) ret = false;
        }
        return ret;
    }

    static if(!hasAttributesForAllParams) {
        import std.conv: text;
        pragma(msg, text("Warning: ", __traits(identifier, testFunction),
                         " passes the criteria for a value-parameterized test function",
                         " but doesn't have the appropriate value UDAs.\n",
                         "         Consider changing its name or annotating it with @DontTest"));
        return [];
    } else {

        static if(arity!testFunction == 1) {
            // bind a range of tuples to prod just as cartesianProduct returns
            enum prod = [GetAttributes!(member, params[0])].map!(a => tuple(a));
        } else {
            import std.conv: text;

            mixin(`enum prod = cartesianProduct(` ~ params.length.iota.map!
                  (a => `[GetAttributes!(member, params[` ~ guaranteedToString(a) ~ `])]`).join(", ") ~ `);`);
        }

        TestData[] testData;
        foreach(comb; aliasSeqOf!prod) {
            enum valuesName = valuesName(comb);

            static if(hasUDA!(member, AutoTags))
                enum extraTags = valuesName.split(".").array;
            else
                enum string[] extraTags = [];


            testData ~= memberTestData!member(
                // testFunction(value0, value1, ...)
                () { testFunction(comb.expand); },
                valuesName,
                extraTags,
            );
        }

        return testData;
    }
}


// template function with @Types
private TestData[] createTypeParamFuncTestData(alias module_, string moduleMember, alias testFunction)
                                              ()
{
    import unit_threaded.attrs: Types, AutoTags;
    import std.traits: getUDAs, hasUDA;

    alias typesAttrs = getUDAs!(testFunction, Types);
    static assert(typesAttrs.length > 0);

    TestData[] testData;

    // To get a cartesian product of all @Types on the function, we use a mixin
    string nestedForEachMixin() {
        import std.array: join, array;
        import std.range: iota, retro;
        import std.algorithm: map;
        import std.conv: text;
        import std.format: format;

        string[] lines;

        string indentation(size_t n) {
            string ret;
            foreach(i; 0 .. n) ret ~= "    ";
            return ret;
        }

        // e.g. 3 -> [type0, type1, type2]
        string typeVars() {
            return typesAttrs.length.iota.map!(i => text(`type`, i)).join(`, `);
        }

        // e.g. 3 -> [int, float, Foo]
        string typeIds() {
            return typesAttrs.length.iota.map!(i => text(`type`, i, `.stringof`)).join(` ~ "." ~ `);
        }

        // nested static foreachs, one per attribute
        lines ~= typesAttrs
            .length
            .iota
            .map!(i => indentation(i) ~ `static foreach(type%s; typesAttrs[%s].types) {`.format(i, i))
            .array
            ;

        lines ~= q{
            {
                static if(hasUDA!(testFunction, AutoTags))
                    enum extraTags = [type0.stringof]; // FIXME
                else
                    enum string[] extraTags = [];

                testData ~= memberTestData!testFunction(
                    () { testFunction!(%s)(); },
                    %s,
                    extraTags
                );
            }
        }.format(typeVars, typeIds);

        // close all static foreach braces
        lines ~= typesAttrs
            .length
            .iota
            .retro
            .map!(i => indentation(i) ~ `}`)
            .array
            ;

        return lines.join("\n");
    }



    enum mixinStr = nestedForEachMixin;
    //pragma(msg, "\n", mixinStr, "\n");
    mixin(mixinStr);

    return testData;
}


// this funtion returns TestData for either classes or test functions
// built-in unittest modules are handled by moduleUnitTests
// pred determines what qualifies as a test
// createTestData must return TestData[]
private TestData[] moduleTestData(alias module_, alias pred, alias createTestData)() pure {
    TestData[] testData;

    foreach(moduleMember; __traits(allMembers, module_)) {

        static if(PassesTestPred!(module_, pred, moduleMember))
            testData ~= createTestData!(module_, moduleMember);
    }

    return testData;

}

// Deprecated: here for backwards compatibility
// TestData for a member of a module (either a test function or a test class)
private TestData memberTestData
    (alias module_, string moduleMember, string[] extraTags = [])
    (TestFunction testFunction = null, string suffix = "")
{
    import std.meta: Alias;
    alias member = Alias!(__traits(getMember, module_, moduleMember));
    return memberTestData!member(testFunction, suffix, extraTags);
}


// TestData for a member of a module (either a test function or a test class)
private TestData memberTestData(alias member)
                               (TestFunction testFunction, string suffix = "", string[] extraTags = [])
{
    import unit_threaded.runner.attrs;
    import std.traits: hasUDA, getUDAs;
    import std.meta: Alias;

    enum singleThreaded = hasUDA!(member, Serial);
    enum builtin = false;
    enum tags = tagsFromAttrs!(getUDAs!(member, Tags));
    enum exceptionTypeInfo = getExceptionTypeInfo!member;
    enum shouldFail = hasUDA!(member, ShouldFail) || hasUDA!(member, ShouldFailWith);
    enum flakyRetries = getFlakyRetries!member;
    // change names if explicitly asked to with a @Name UDA
    enum nameFromAttr = TestNameFromAttr!member;

    static if(nameFromAttr == "")
        enum name = __traits(identifier, member);
    else
        enum name = nameFromAttr;

    alias module_ = Alias!(__traits(parent, member));

    return TestData(fullyQualifiedName!module_~ "." ~ name,
                    testFunction,
                    hasUDA!(member, HiddenTest),
                    shouldFail,
                    singleThreaded,
                    builtin,
                    suffix,
                    tags ~ extraTags,
                    exceptionTypeInfo,
                    flakyRetries);
}

private int getFlakyRetries(alias test)() {
    import unit_threaded.runner.attrs: Flaky;
    import std.traits: getUDAs;
    import std.conv: text;

    alias flakies = getUDAs!(test, Flaky);

    static assert(flakies.length == 0 || flakies.length == 1,
                  text("Only 1 @Flaky allowed, found ", flakies.length, " on ",
                       __traits(identifier, test)));

    static if(flakies.length == 1) {
        static if(is(flakies[0]))
            return Flaky.defaultRetries;
        else
            return flakies[0].retries;
    } else
        return 0;
}

string[] tagsFromAttrs(T...)() {
    static assert(T.length <= 1, "@Tags can only be applied once");
    static if(T.length)
        return T[0].values;
    else
        return [];
}
