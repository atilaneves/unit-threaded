import TestCase;
import std.stdio;

class Foo: TestCase {
    override void test() {
        print(5, 3);
    }
}


void main() {
    writeln("Testing Unit Threaded code...");
    auto foo = new Foo;
    foo.run();
}
