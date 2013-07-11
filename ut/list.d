module ut.list;

import std.traits;
import std.uni;
import std.typecons;

string[] getTestClassNames(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes;
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            classes ~= fullyQualifiedName!mod ~ "." ~ klass;
        }
    }

    return classes;
}


alias void function() TestFunction;
alias Tuple!(string, TestFunction) TestFunctionTuple;

auto getTestFunctions(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    TestFunctionTuple[] functions;
    foreach(moduleMember; __traits(allMembers, mod)) {
        static immutable prefix = "test";
        static immutable minSize = prefix.length + 1;
        static if(moduleMember.length >= minSize && moduleMember[0 .. prefix.length] == "test" &&
                  isUpper(moduleMember[prefix.length])) {
            //I couldn't find a way to check for access here. I tried __traits(getProtection)
            //and got 'public' for private functions

            static immutable funcName = fullyQualifiedName!mod ~ "." ~ moduleMember;
            static immutable funcAddr = "&" ~ funcName;

            mixin("TestFunctionTuple tuple;");
            mixin("tuple[0] = \"" ~ funcName ~ "\";");
            mixin("tuple[1] = " ~ funcAddr ~ ";");
            mixin("functions ~= tuple;");
        }
    }

    return functions;
}


private auto addModule(string[] elements, string mod = "ut.tests.module_with_tests") {
    import std.algorithm;
    import std.array;
    return array(map!(a => mod ~ "." ~ a)(elements));
}

import ut.tests.module_with_tests; //defines tests and non-tests
import ut.asserts;

unittest {
    const expected = addModule([ "FooTest", "BarTest" ]);
    const actual = getTestClassNames!(ut.tests.module_with_tests)();
    assertEqual(actual, expected);
}

unittest {
    TestFunctionTuple fooTuple; fooTuple[0] = "ut.tests.module_with_tests.testFoo"; fooTuple[1] = &testFoo;
    TestFunctionTuple barTuple; barTuple[0] = "ut.tests.module_with_tests.testBar"; barTuple[1] = &testBar;
    const expected = [ fooTuple, barTuple ];
    const actual = getTestFunctions!(ut.tests.module_with_tests)();
    assertEqual(actual, expected);
}
