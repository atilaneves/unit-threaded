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


///
alias TestFunction = void delegate();

/**
 * Attributes of each test.
 */
struct TestData {
    string name;
    TestFunction testFunction;
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
}


/**
 * Finds all test cases.
 * Template parameters are module strings.
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
 * Finds all test cases.
 * Template parameters are module symbols.
 */
const(TestData)[] allTestData(MOD_SYMBOLS...)()
    if(!from!"std.meta".anySatisfy!(from!"std.traits".isSomeString, typeof(MOD_SYMBOLS)))
{
    return moduleUnitTests!MOD_SYMBOLS;
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
        import std.meta: Filter;

        // cheap target for implicit conversion
        string str__;

        // weird name for hygiene reasons
        foreach(index, eLtEstO; __traits(getUnitTests, composite)) {
            // make common case cheap: @("name") unittest {}
            static if(__traits(getAttributes, eLtEstO).length == 1
                && __traits(compiles, str__ = __traits(getAttributes, eLtEstO)[0])
            ) {
                enum prefix = fullyQualifiedName!(__traits(parent, eLtEstO)) ~ ".";
                enum name = prefix ~ __traits(getAttributes, eLtEstO)[0];
                enum hidden = false;
                enum shouldFail = false;
                enum singleThreaded = false;
                enum tags = string[].init;
                enum exceptionTypeInfo = TypeInfo.init;
                enum flakyRetries = 0;
            } else {
                enum name = unittestName!(eLtEstO, index);
                enum hidden = hasUDA!(eLtEstO, HiddenTest);
                enum shouldFail = hasUDA!(eLtEstO, ShouldFail) || hasUDA!(eLtEstO, ShouldFailWith);
                enum singleThreaded = hasUDA!(eLtEstO, Serial);
                enum isTags(alias T) = is(typeof(T)) && is(typeof(T) == Tags);
                enum tags = tagsFromAttrs!(Filter!(isTags, __traits(getAttributes, eLtEstO)));
                enum exceptionTypeInfo = getExceptionTypeInfo!eLtEstO;
                enum flakyRetries = getFlakyRetries!(eLtEstO);
            }
            enum builtin = true;
            enum suffix = "";

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
