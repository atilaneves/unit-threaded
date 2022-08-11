module unit_threaded.ut.behave;

import unit_threaded.behave;
import unit_threaded.runner.io;

unittest {
    import std.algorithm: map;
    import std.exception: enforce;
    import std.string: splitLines;
    import unit_threaded.runner.testcase: TestCase;
    import unit_threaded.should;

    class TestOutput: Output {
        string output;
        override void send(in string output) {
            this.output ~= output;
        }
        override void flush(bool failed) {}
    }

    class BehaveTest: TestCase {
        override void test() {
            given("the given step");
            when("the when step");
            then("the then step");
            enforce!UnitTestError(false);
        }
        override string getPath() @safe pure nothrow const {
            return "BehaveTest";
        }
    }

    auto test = new BehaveTest;
    auto writer = new TestOutput;
    test.setOutput(writer);

    test();
    if (_useEscCodes) {
        writer.output.splitLines.map!escapeAnsi.shouldEqual([
            "BehaveTest:",
            "",
            "(tab)(intense)Given(normal) the given step      # behave.d:23(clearLine)",
            "(green)(tab)(intense)Given(normal) the given step(default)      # behave.d:23",
            "(tab)(intense)When(normal) the when step        # behave.d:24(clearLine)",
            "(green)(tab)(intense)When(normal) the when step(default)        # behave.d:24",
            "(tab)(intense)Then(normal) the then step        # behave.d:25(clearLine)",
            "    tests/unit_threaded/ut/behave.d:26 - Enforcement failed",
            "",
            "(red)(tab)(intense)Then(normal) the then step(default)        # behave.d:25",
            "",
        ]);
    } else {
        writer.output.splitLines.map!escapeAnsi.shouldEqual([
            "BehaveTest:",
            "",
            "(tab)Given the given step      # behave.d:23",
            "(tab)When the when step        # behave.d:24",
            "    tests/unit_threaded/ut/behave.d:26 - Enforcement failed",
            "",
            "(tab)Then the then step        # behave.d:25",
            "",
        ]);
    }
}

private string escapeAnsi(string line) {
    import std.string: replace;

    return line
        .replace("\033[1m", "(intense)")
        .replace("\033[31m", "(red)")
        .replace("\033[32m", "(green)")
        .replace("\033[39m", "(default)")
        .replace("\033[22m", "(normal)")
        .replace("\033[2K", "(clearLine)")
        .replace("\t", "(tab)")
        .replace("\033", "\\033");
}
