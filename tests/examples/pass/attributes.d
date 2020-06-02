module tests.pass.attributes;

import unit_threaded;

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


@ShouldFail
unittest {
     assert(false);
}


@Flaky
unittest {
    static int i = 0;
    if(i++ % 2 == 0) throw new Exception("oops");
}
