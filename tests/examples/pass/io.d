module tests.pass.io;

import unit_threaded;


class TestIo: TestCase {
    override void test() {
        writelnUt("Class writelnUt should only print with '-d' option");
    }
}

void testNoIo1() {
    writelnUt("But this should show up when using -d option");
}
