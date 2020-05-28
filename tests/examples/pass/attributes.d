module tests.pass.attributes;

import unit_threaded;
import tests.pass.types;

enum myEnumNum = "foo.bar"; //there was a bug that made this not compile
enum myOtherEnumNum;

@Tags("tagged")
unittest {
    //tests that using the @UnitTest UDA adds this function
    //to the list of tests despite its name
    1.shouldEqual(1);
}


@HiddenTest("Bug id #54321")
unittest {
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}

@HiddenTest
unittest {
    null.shouldNotBeNull; //hidden by default, fails if explicitly run
}


@ShouldFail("Bug id 12345")
unittest {
    3.shouldEqual(4);
}


@ShouldFail("Bug id 12345")
unittest {
    throw new Exception("This should not be seen");
}

@Tags("tagged")
@Name("first_unit_test")
unittest {
    writelnUt("First unit test block\n");
    assert(true); //unit test block that always passes
}


@Name("second_unit_test")
unittest {
    writelnUt("Second unit test block\n");
    assert(true); //unit test block that always passes
}

@Tags(["untagged", "unhinged"])
@("third_unit_test")
unittest {
    3.shouldEqual(3);
}

@ShouldFail
unittest {
    3.shouldEqual(5);
}

@Tags("other", "more")
@UnitTest
@(42, 2)
void values(int i) {
    (i % 2 == 0).shouldBeTrue;
}


@ShouldFail
unittest {
     assert(false);
}

@ShouldFail
@(12, 14)
@UnitTest
void issue14(int i) {
    (i % 2 == 0).shouldBeFalse;
}

@UnitTest
@Types!(int, byte)
void template_(T)() {
    T.init.shouldEqual(0);
}

@UnitTest
@Types!(A)
void templateWithTypeFromAnotherModule(T)() {

}

@("Built-in with values")
@Values("red", "goo")
unittest {
    getValue!string.length.shouldEqual(3);
}

@("Built-in with values range")
@Values(["red", "goo"])
unittest {
    getValue!string.length.shouldEqual(3);
}

@("Test_parse_hostgroup")
@Values("abc", "abc1", "abc.xyz", "abc1.xyz", "abc12345.xyz.asd")
unittest {
    import std.algorithm: startsWith;
    string val = getValue!(string);
    val.startsWith("abc").shouldBeTrue;
}

@Flaky
unittest {
    static int i = 0;
    if(i++ % 2 == 0) throw new Exception("oops");
}
