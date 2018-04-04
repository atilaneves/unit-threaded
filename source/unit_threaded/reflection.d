/**
   Compile-time reflection to find unit tests and set their properties.
 */
module unit_threaded.reflection;

import unit_threaded.from;
/*
   These standard library imports contain something important for the code below.
   Unfortunately I don't know what they are so they're to prevent breakage.
 */
import std.traits;
import std.algorithm;
import std.array;


///
alias void delegate() TestFunction;

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
    auto allTestsWithFunc(string expr)() pure {
        import std.traits: ReturnType;
        import std.meta: AliasSeq;
        //tests is whatever type expr returns
        ReturnType!(mixin(expr ~ q{!(MOD_SYMBOLS[0])})) tests;
        foreach(module_; AliasSeq!MOD_SYMBOLS) {
            tests ~= mixin(expr ~ q{!module_()}); //e.g. tests ~= moduleTestClasses!module_
        }
        return tests;
    }

    return allTestsWithFunc!"moduleTestClasses" ~
           allTestsWithFunc!"moduleTestFunctions" ~
           allTestsWithFunc!"moduleUnitTests";
}


private template Identity(T...) if(T.length > 0) {
    static if(__traits(compiles, { alias x = T[0]; }))
        alias Identity = T[0];
    else
        enum Identity = T[0];
}


/**
 * Finds all built-in unittest blocks in the given module.
 * Recurses into structs, classes, and unions of the module.
 *
 * @return An array of TestData structs
 */
TestData[] moduleUnitTests(alias module_)() pure nothrow {

    // Return a name for a unittest block. If no @Name UDA is found a name is
    // created automatically, else the UDA is used.
    // the weird name for the first template parameter is so that it doesn't clash
    // with a package name
    string unittestName(alias _theUnitTest, int index)() @safe nothrow {
        import std.conv: text, to;
        import std.traits: fullyQualifiedName;
        import std.traits: getUDAs;
        import std.meta: Filter;
        import unit_threaded.attrs: Name;

        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        enum nameAttrs = getUDAs!(_theUnitTest, Name);
        static assert(nameAttrs.length == 0 || nameAttrs.length == 1, "Found multiple Name UDAs on unittest");

        enum strAttrs = Filter!(isStringUDA, __traits(getAttributes, _theUnitTest));
        enum hasName = nameAttrs.length || strAttrs.length == 1;
        enum prefix = fullyQualifiedName!(__traits(parent, _theUnitTest)) ~ ".";

        static if(hasName) {
            static if(nameAttrs.length == 1)
                return prefix ~ nameAttrs[0].value;
            else
                return prefix ~ strAttrs[0];
        } else {
            string name;
            try {
                return prefix ~ "unittest" ~ (index).to!string;
            } catch(Exception) {
                assert(false, text("Error converting ", index, " to string"));
            }
        }
    }

    void function() getUDAFunction(alias composite, alias uda)() pure nothrow {
        import std.traits: fullyQualifiedName, moduleName, isSomeFunction, hasUDA;

        // Due to:
        // https://issues.dlang.org/show_bug.cgi?id=17441
        // moduleName!composite might fail, so we try to import that only if
        // if compiles, then try again with fullyQualifiedName
        enum moduleNameStr = `import ` ~ moduleName!composite ~ `;`;
        enum fullyQualifiedStr = `import ` ~ fullyQualifiedName!composite ~ `;`;

        static if(__traits(compiles, mixin(moduleNameStr)))
            mixin(moduleNameStr);
        else static if(__traits(compiles, mixin(fullyQualifiedStr)))
            mixin(fullyQualifiedStr);

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

        import unit_threaded.attrs;
        import unit_threaded.uda: hasUtUDA;
        import std.traits: hasUDA;
        import std.meta: Filter, aliasSeqOf;
        import std.algorithm: map, cartesianProduct;

        foreach(index, eLtEstO; __traits(getUnitTests, composite)) {

            enum dontTest = hasUDA!(eLtEstO, DontTest);

            static if(!dontTest) {

                enum name = unittestName!(eLtEstO, index);
                enum hidden = hasUDA!(eLtEstO, HiddenTest);
                enum shouldFail = hasUDA!(eLtEstO, ShouldFail) || hasUtUDA!(eLtEstO, ShouldFailWith);
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
        import std.traits: fullyQualifiedName;

        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        if (composite.mangleof in visitedMembers)
            return;
        visitedMembers[composite.mangleof] = true;
        addMemberUnittests!composite();
        foreach(member; __traits(allMembers, composite)){
            enum notPrivate = __traits(compiles, mixin(member)); //only way I know to check if private
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
        enum notPrivate = __traits(compiles, child.init); //only way I know to check if private
        static if (is(child == class) || is(child == struct) || is(child == union)) {
            addUnitTestsRecursively!child;
        }
    }

    addUnitTestsRecursively!module_();
    return testData;
}

private TypeInfo getExceptionTypeInfo(alias Test)() {
    import unit_threaded.uda: hasUtUDA, getUtUDAs;
    import unit_threaded.attrs: ShouldFailWith;

    static if(hasUtUDA!(Test, ShouldFailWith)) {
        alias uda = getUtUDAs!(Test, ShouldFailWith)[0];
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
    import unit_threaded.uda: HasTypes;

    alias ut_mmbr__ = Identity!(__traits(getMember, module_, moduleMember));

    static if(__traits(compiles, isSomeFunction!(ut_mmbr__))) {
        static if(__traits(compiles, &ut_mmbr__))
            enum isPrivate = false;
        else static if(__traits(compiles, new ut_mmbr__))
            enum isPrivate = false;
        else static if(__traits(compiles, HasTypes!ut_mmbr__))
            enum isPrivate = !HasTypes!ut_mmbr__;
        else
            enum isPrivate = true;
    } else {
        enum isPrivate = true;
    }
}


// if this member is a test function or class, given the predicate
private template PassesTestPred(alias module_, alias pred, string moduleMember) {
    import std.traits: fullyQualifiedName;
    import unit_threaded.meta: importMember;
    import unit_threaded.uda: HasAttribute;
    import unit_threaded.attrs: DontTest;

    //should be the line below instead but a compiler bug prevents it
    //mixin(importMember!module_(moduleMember));
    mixin("import " ~ fullyQualifiedName!module_ ~ ";");
    alias I(T...) = T;
    static if(!__traits(compiles, I!(__traits(getMember, module_, moduleMember)))) {
        enum PassesTestPred = false;
    } else {
        alias member = I!(__traits(getMember, module_, moduleMember));

        template canCheckIfSomeFunction(T...) {
            enum canCheckIfSomeFunction = T.length == 1 && __traits(compiles, isSomeFunction!(T[0]));
        }

        private string funcCallMixin(alias T)() {
            import std.conv: to;
            string[] args;
            foreach(i, ParamType; Parameters!T) {
                args ~= `arg` ~ i.to!string;
            }

            return moduleMember ~ `(` ~ args.join(`,`) ~ `);`;
        }

        private string argsMixin(alias T)() {
            import std.conv: to;
            string[] args;
            foreach(i, ParamType; Parameters!T) {
                args ~= ParamType.stringof ~ ` arg` ~ i.to!string ~ `;`;
            }

            return args.join("\n");
        }

        template canCallMember() {
            void _f() {
                mixin(argsMixin!member);
                mixin(funcCallMixin!member);
            }
        }

        template canInstantiate() {
            void _f() {
                mixin(`auto _ = new ` ~ moduleMember ~ `;`);
            }
        }

        template isPrivate() {
            static if(!canCheckIfSomeFunction!member) {
                enum isPrivate = !__traits(compiles, __traits(getMember, module_, moduleMember));
            } else {
                static if(isSomeFunction!member) {
                    enum isPrivate = !__traits(compiles, canCallMember!());
                } else static if(is(member)) {
                    static if(isAggregateType!member)
                        enum isPrivate = !__traits(compiles, canInstantiate!());
                    else
                        enum isPrivate = !__traits(compiles, __traits(getMember, module_, moduleMember));
                } else {
                    enum isPrivate = !__traits(compiles, __traits(getMember, module_, moduleMember));
                }
            }
        }

        enum notPrivate = !isPrivate!();
        enum PassesTestPred = !isPrivate!() && pred!(module_, moduleMember) &&
            !HasAttribute!(module_, moduleMember, DontTest);
    }
}


/**
 * Finds all test classes (classes implementing a test() function)
 * in the given module
 */
TestData[] moduleTestClasses(alias module_)() pure nothrow {

    template isTestClass(alias module_, string moduleMember) {
        import unit_threaded.meta: importMember;
        import unit_threaded.uda: HasAttribute;
        import unit_threaded.attrs: UnitTest;
        import std.traits: isAggregateType;

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
            enum hasUnitTest = HasAttribute!(module_, moduleMember, UnitTest);
            enum hasTestMethod = __traits(hasMember, member, "test");

            enum isTestClass = is(member == class) && (hasTestMethod || hasUnitTest);
        }
    }

    return moduleTestData!(module_, isTestClass, memberTestData);
}


/**
 * Finds all test functions in the given module.
 * Returns an array of TestData structs
 */
TestData[] moduleTestFunctions(alias module_)() pure {

    import unit_threaded.uda: isTypesAttr;

    template isTestFunction(alias module_, string moduleMember) {
        import unit_threaded.meta: importMember;
        import unit_threaded.attrs: UnitTest;
        import unit_threaded.uda: HasAttribute, GetTypes;
        import std.meta: AliasSeq;
        import std.traits: isSomeFunction;

        alias member = Identity!(__traits(getMember, module_, moduleMember));

        static if(.isPrivate!(module_, moduleMember)) {
            enum isTestFunction = false;
        } else static if(AliasSeq!(member).length != 1) {
            enum isTestFunction = false;
        } else static if(isSomeFunction!member) {
            enum isTestFunction = hasTestPrefix!(module_, moduleMember) ||
                                  HasAttribute!(module_, moduleMember, UnitTest);
        } else static if(__traits(compiles, __traits(getAttributes, member))) {
            // in this case we handle the possibility of a template function with
            // the @Types UDA attached to it
            alias types = GetTypes!member;
            enum isTestFunction = hasTestPrefix!(module_, moduleMember) &&
                                  types.length > 0;
        } else {
            enum isTestFunction = false;
        }

    }

    template hasTestPrefix(alias module_, string memberName) {
        import std.uni: isUpper;
        import unit_threaded.meta: importMember;

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

    return moduleTestData!(module_, isTestFunction, createFuncTestData);
}

private TestData[] createFuncTestData(alias module_, string moduleMember)() {
    import unit_threaded.meta: importMember;
    import unit_threaded.uda: GetAttributes, HasAttribute, GetTypes, HasTypes;
    import unit_threaded.attrs;
    import std.meta: aliasSeqOf;

    mixin(importMember!module_(moduleMember));
    /*
      Get all the test functions for this module member. There might be more than one
      when using parametrized unit tests.

      Examples:
      ------
      void testFoo() {} // -> the array contains one element, testFoo
      @(1, 2, 3) void testBar(int) {} // The array contains 3 elements, one for each UDA value
      @Types!(int, float) void testBaz(T)() {} //The array contains 2 elements, one for each type
      ------
    */
    // if the predicate returned true (which is always the case here), then it's either
    // a regular function or a templated one. If regular we can get a pointer to it
    enum isRegularFunction = __traits(compiles, &__traits(getMember, module_, moduleMember));

    static if(isRegularFunction) {

        enum func = &__traits(getMember, module_, moduleMember);
        enum arity = arity!func;

        static if(arity == 0)
            // the reason we're creating a lambda to call the function is that test functions
            // are ordinary functions, but we're storing delegates
            return [ memberTestData!(module_, moduleMember)(() { func(); }) ]; //simple case, just call the function
        else {

            // the function has parameters, check if it has UDAs for value parameters to be passed to it
            alias params = Parameters!func;

            import std.range: iota;
            import std.algorithm: any;
            import std.typecons: tuple, Tuple;

            bool hasAttributesForAllParams() {
                auto ret = true;
                foreach(p; params) {
                    if(tuple(GetAttributes!(module_, moduleMember, p)).length == 0) {
                        ret = false;
                    }
                }
                return ret;
            }

            static if(!hasAttributesForAllParams) {
                import std.conv: text;
                pragma(msg, text("Warning: ", moduleMember, " passes the criteria for a value-parameterized test function",
                                 " but doesn't have the appropriate value UDAs.\n",
                                 "         Consider changing its name or annotating it with @DontTest"));
                return [];
            } else {

                static if(arity == 1) {
                    // bind a range of tuples to prod just as cartesianProduct returns
                    enum prod = [GetAttributes!(module_, moduleMember, params[0])].map!(a => tuple(a));
                } else {
                    import std.conv: text;

                    mixin(`enum prod = cartesianProduct(` ~ params.length.iota.map!
                          (a => `[GetAttributes!(module_, moduleMember, params[` ~ guaranteedToString(a) ~ `])]`).join(", ") ~ `);`);
                }

                TestData[] testData;
                foreach(comb; aliasSeqOf!prod) {
                    enum valuesName = valuesName(comb);

                    static if(HasAttribute!(module_, moduleMember, AutoTags))
                        enum extraTags = valuesName.split(".").array;
                    else
                        enum string[] extraTags = [];


                    testData ~= memberTestData!(module_, moduleMember, extraTags)(
                        // func(value0, value1, ...)
                        () { func(comb.expand); },
                        valuesName);
                }

                return testData;
            }
        }
    } else static if(HasTypes!(mixin(moduleMember))) { //template function with @Types
        alias types = GetTypes!(mixin(moduleMember));
        TestData[] testData;
        foreach(type; types) {

            static if(HasAttribute!(module_, moduleMember, AutoTags))
                enum extraTags = [type.stringof];
            else
                enum string[] extraTags = [];

            alias member = Identity!(mixin(moduleMember));

            testData ~= memberTestData!(module_, moduleMember, extraTags)(
                () { member!type(); },
                type.stringof);
        }
        return testData;
    } else {
        return [];
    }
}



// this funtion returns TestData for either classes or test functions
// built-in unittest modules are handled by moduleUnitTests
// pred determines what qualifies as a test
// createTestData must return TestData[]
private TestData[] moduleTestData(alias module_, alias pred, alias createTestData)() pure {
    import std.traits: fullyQualifiedName;
    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

    TestData[] testData;

    foreach(moduleMember; __traits(allMembers, module_)) {

        static if(PassesTestPred!(module_, pred, moduleMember))
            testData ~= createTestData!(module_, moduleMember);
    }

    return testData;

}

// TestData for a member of a module (either a test function or test class)
private TestData memberTestData(alias module_, string moduleMember, string[] extraTags = [])
    (TestFunction testFunction = null, string suffix = "") {

    import unit_threaded.uda: HasAttribute, GetAttributes, hasUtUDA;
    import unit_threaded.attrs;
    import std.traits: fullyQualifiedName;

    mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

    immutable singleThreaded = HasAttribute!(module_, moduleMember, Serial);
    enum builtin = false;
    enum tags = tagsFromAttrs!(GetAttributes!(module_, moduleMember, Tags));
    enum exceptionTypeInfo = getExceptionTypeInfo!(mixin(moduleMember));
    enum shouldFail =
        HasAttribute!(module_, moduleMember, ShouldFail) ||
        hasUtUDA!(mixin(moduleMember), ShouldFailWith);
    enum flakyRetries = getFlakyRetries!(mixin(moduleMember));

    return TestData(fullyQualifiedName!module_~ "." ~ moduleMember,
                    testFunction,
                    HasAttribute!(module_, moduleMember, HiddenTest),
                    shouldFail,
                    singleThreaded,
                    builtin,
                    suffix,
                    tags ~ extraTags,
                    exceptionTypeInfo,
                    flakyRetries);
}

private int getFlakyRetries(alias test)() {
    import unit_threaded.attrs: Flaky;
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
