import testsuite;
import testcase;
import std.stdio;

class Foo: TestCase {
    override void test() {
        assertTrue(5 == 3);
        assertFalse(5 == 5);
        assertEqual(5, 5);
        assertNotEqual(5, 3);
        assertEqual(5, 3);
    }
}


void main() {
    writeln("Testing Unit Threaded code...");
    TestCase[] tests = [ new Foo ];
    auto suite = TestSuite(tests);
    immutable elapsed = suite.run();
    writeln("Time taken: ", elapsed, " seconds");
    writeln(suite.getNumTestsRun(), " test(s) run, ",
            suite.getNumFailures(), " failed.\n");
    auto foo = new Foo;
    auto result = foo.run();
    write(result.output);
}
