module unit_threaded.tests.module_with_tests;
import unit_threaded.check;

//test functions
void testFoo() {}
void testBar() {}
private void testPrivate() { } //should not show up
@UnitTest void funcThatShouldShowUpCosOfAttr() { }

//non-test functions
private void someFun() {}
private void testosterone() {}
private void tes() {}

//test classes
class FooTest { void test() { } }
class BarTest { void test() { } }
@UnitTest class Blergh { }

//non-test classes
class NotATest { void tes() { } }
class AlsoNotATest { void testosterone() { } }
