module tests.fail.normal;

import unit_threaded;


class WrongTest: TestCase {
    override void test() {
        shouldBeTrue(5 == 3);
        shouldBeFalse(5 == 5);
        5.shouldEqual(5);
        5.shouldNotEqual(3);
        5.shouldEqual(3);
    }
}

class OtherWrongTest: TestCase {
    override void test() {
        shouldBeTrue(false);
    }
}

class RightTest: TestCase {
    override void test() {
        shouldBeTrue(true);
    }
}

void testTrue() {
    shouldBeTrue(true);
}

void testEqualVars() {
    immutable foo = 4;
    immutable bar = 6;
    foo.shouldEqual(bar);
}

void someFun() {
    //not going to be executed as part of the testsuite,
    //doesn't obey the naming convention
    assert(0, "Never going to happen");
}

void testStringEqual() {
    "foo".shouldEqual("bar");
}

void testStringEqualFails() {
    "foo".shouldEqual("bar");
}

void testStringNotEqual() {
    "foo".shouldNotEqual("foo");
}

unittest {
    const str = "unittest block that always fails";
    writelnUt(str);
    assert(3 == 4, str);
}

void testIntArray() {
    [1, 2, 4].shouldEqual([1, 2, 3]);
}

void testStringArray() {
    ["foo", "baz", "badoooooooooooo!"].shouldEqual(["foo", "bar", "baz"]);
}
