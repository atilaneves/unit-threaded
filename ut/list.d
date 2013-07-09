module ut.list;

import ut.asserts;
import std.traits;
import std.uni;

string[] getTestClassNames(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] classes = [];
    foreach(klass; __traits(allMembers, mod)) {
        static if(__traits(compiles, mixin(klass)) && __traits(hasMember, mixin(klass), "test")) {
            classes ~= fullyQualifiedName!mod ~ "." ~ klass;
        }
    }

    return classes;
}

string[] getTestFunctions(alias mod)() {
    mixin("import " ~ fullyQualifiedName!mod ~ ";"); //so it's visible
    string[] functions = [];
    foreach(moduleMember; __traits(allMembers, mod)) {
        static immutable prefix = "test";
        static immutable minSize = prefix.length + 1;
        static if(moduleMember.length >= minSize && moduleMember[0 .. prefix.length] == "test" &&
                  isUpper(moduleMember[prefix.length])) {
            functions ~= fullyQualifiedName!mod ~ "." ~ moduleMember;
        }
    }

    return functions;
}

string[] getTestables(alias mod)() {
    return getTestClassNames!mod ~ getTestFunctions!mod;
}


unittest {
    import ut.tests.module_with_tests; //defines tests and non-tests
    const expectedFuncs = [ "ut.tests.module_with_tests.testFoo", "ut.tests.module_with_tests.testBar" ];
    const actualFuncs = getTestFunctions!(ut.tests.module_with_tests)();
    assertEqual(actualFuncs, expectedFuncs);
}
