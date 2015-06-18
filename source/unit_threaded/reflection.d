module unit_threaded.reflection;

import unit_threaded.attrs;
import std.traits : fullyQualifiedName, isSomeString;
import std.typetuple : Filter;

//copied from phobos 2.068
template hasUDA(alias symbol, alias attribute)
{
    import std.typetuple : staticIndexOf;
    import std.traits : staticMap;

    static if (is(attribute == struct) || is(attribute == class))
    {
        template GetTypeOrExp(alias S)
        {
            static if (is(typeof(S)))
                alias GetTypeOrExp = typeof(S);
            else
                alias GetTypeOrExp = S;
        }
        enum bool hasUDA = staticIndexOf!(attribute, staticMap!(GetTypeOrExp,
                __traits(getAttributes, symbol))) != -1;
    }
    else
        enum bool hasUDA = staticIndexOf!(attribute, __traits(getAttributes, symbol)) != -1;
}


/**
 * Unit test function type.
 */
alias TestFunction = void function();

/**
 * Unit test data
 */
struct TestData
{
    string name;
    TestFunction testFunction;
    bool hidden;
    bool shouldFail;
    bool singleThreaded;
}

/**
 * Finds all test cases (functions, classes, built-in unittest blocks)
 * Template parameters are module symbols or their string representation.
 * Examples:
 * -----
 * import my.test.module;
 * auto testData = allTestData!(my.test.module, "other.test.module");
 * -----
 */
TestData[] allTestData(MODULES...)() @safe pure nothrow
{
    TestData[] testData;

    foreach (module_; MODULES)
    {
        static if (is(typeof(module_)) && isSomeString!(typeof(module_)))
        {
            //string, generate the code
            mixin("import " ~ module_ ~ ";");
            testData ~= moduleTestData!(mixin(module_));
        }
        else
        {
            //module symbol, just add normally
            testData ~= moduleTestData!(module_);
        }
    }

    return testData;
}

/**
 * Finds all built-in unittest blocks in the given module_.
 * Params:
 *   module_ = The module to reflect on. Can be a symbol or a string.
 * Returns: An array of TestData structs
 */
TestData[] moduleTestData(alias module_)() @safe pure nothrow
{

    // Return a name for a unittest block. If no @name UDA is found a name is
    // created automatically, else the UDA is used.
    string unittestName(alias test, int index)() @safe nothrow
    {
        mixin("import " ~ fullyQualifiedName!module_ ~ ";"); //so it's visible

        enum isName(alias T) = is(typeof(T)) && is(typeof(T) == name);
        alias names = Filter!(isName, __traits(getAttributes, test));
        static assert(names.length == 0 || names.length == 1,
            "Found multiple @name UDAs on unittest");
        enum prefix = fullyQualifiedName!module_ ~ ".";

        static if (names.length == 1)
        {
            return prefix ~ names[0].value;
        }
        else
        {
            import std.conv;

            return prefix ~ "unittest" ~ index.to!string;
        }
    }

    TestData[] testData;
    foreach (index, test; __traits(getUnitTests, module_))
    {
        testData ~= TestData(unittestName!(test, index), &test,
            hasUDA!(test, hiddenTest), hasUDA!(test, shouldFail),
            hasUDA!(test, singleThreaded),);
    }
    return testData;
}
