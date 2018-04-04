module unit_threaded.ut.io;

import unit_threaded.io;

unittest {
    import unit_threaded.testcase: TestCase;
    import unit_threaded.should;
    import std.string: splitLines;

    enableDebugOutput(false);

    class TestOutput: Output {
        string output;
        override void send(in string output) {
            import std.conv: text;
            this.output ~= output;
        }

        override void flush() {}
    }

    class PrintTest: TestCase {
        override void test() {
            writelnUt("foo", "bar");
        }
        override string getPath() @safe pure nothrow const {
            return "PrintTest";
        }
    }

    auto test = new PrintTest;
    auto writer = new TestOutput;
    test.setOutput(writer);
    test();

    writer.output.splitLines.shouldEqual(
        [
            "PrintTest:",
        ]
    );
}

unittest {
    import unit_threaded.should;
    import unit_threaded.testcase: TestCase;
    import unit_threaded.reflection: TestData;
    import unit_threaded.factory: createTestCase;
    import std.traits: fullyQualifiedName;
    import std.string: splitLines;

    enableDebugOutput;
    scope(exit) enableDebugOutput(false);

    class TestOutput: Output {
        string output;
        override void send(in string output) {
            import std.conv: text;
            this.output ~= output;
        }

        override void flush() {}
    }

    class PrintTest: TestCase {
        override void test() {
            writelnUt("foo", "bar");
        }
        override string getPath() @safe pure nothrow const {
            return "PrintTest";
        }
    }

    auto test = new PrintTest;
    auto writer = new TestOutput;
    test.setOutput(writer);
    test();

    writer.output.splitLines.shouldEqual(
        [
            "PrintTest:",
            "foobar",
        ]
    );
}



struct FakeFile {
    string fileName;
    string mode;
    string output;
    void flush() shared {}
    void write(in string s) shared {
        output ~= s.dup;
    }
    string[] lines() shared const @safe pure {
        import std.string: splitLines;
        return output.splitLines;
    }
}
shared FakeFile gOut;
shared FakeFile gErr;
void resetFakeFiles() {
    synchronized {
        gOut = FakeFile("out", "mode");
        gErr = FakeFile("err", "mode");
    }
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly;
    import unit_threaded.should;

    enableDebugOutput(false);
    resetFakeFiles;

    auto tid = spawn(&threadWriter!(gOut, gErr), thisTid);
    tid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    gOut.shouldEqual(shared FakeFile(nullFileName, "w"));
    gErr.shouldEqual(shared FakeFile(nullFileName, "w"));

    tid.send(ThreadFinish());
    receiveOnly!ThreadEnded;
}

unittest {
    import std.concurrency: spawn, send, thisTid, receiveOnly;
    import unit_threaded.should;

    enableDebugOutput(true);
    scope(exit) enableDebugOutput(false);
    resetFakeFiles;

    auto tid = spawn(&threadWriter!(gOut, gErr), thisTid);
    tid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    gOut.shouldEqual(shared FakeFile("out", "mode"));
    gErr.shouldEqual(shared FakeFile("err", "mode"));

    tid.send(ThreadFinish());
    receiveOnly!ThreadEnded;
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly;
    import unit_threaded.should;

    resetFakeFiles;

    auto tid = spawn(&threadWriter!(gOut, gErr), thisTid);
    tid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    tid.send("foobar\n", thisTid);
    tid.send("toto\n", thisTid);
    gOut.output.shouldBeEmpty; // since it writes to the old gOut

    tid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    // gOut is restored so the output should be here
    gOut.lines.shouldEqual(
        [
            "foobar",
            "toto",
            ]
        );
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly, Tid;
    import unit_threaded.should;

    resetFakeFiles;

    auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
    writerTid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    writerTid.send("foobar\n", thisTid);
    auto otherTid = spawn(
        (Tid writerTid, Tid testTid) {
            import std.concurrency: send, receiveOnly, OwnerTerminated, thisTid;
            try {
                writerTid.send("what about me?\n", thisTid);
                testTid.send(true);
                receiveOnly!bool;

                writerTid.send("seriously, what about me?\n", thisTid);
                testTid.send(true);
                receiveOnly!bool;

                writerTid.send(Flush(), thisTid);
                testTid.send(true);
                receiveOnly!bool;

                writerTid.send("final attempt\n", thisTid);
                testTid.send(true);

            } catch(OwnerTerminated ex) {}
        },
        writerTid,
        thisTid);
    receiveOnly!bool; //wait for otherThread 1st message

    writerTid.send("toto\n", thisTid);
    otherTid.send(true); //tell otherThread to continue
    receiveOnly!bool; //wait for otherThread 2nd message

    writerTid.send("last one from me\n", thisTid);
    otherTid.send(true); // tell otherThread to continue
    receiveOnly!bool; // wait for otherThread to try and flush (won't work)

    writerTid.send(Flush(), thisTid); //finish with our output
    otherTid.send(true); //finish
    receiveOnly!bool; // wait for otherThread to finish

    writerTid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    // gOut is restored so the output should be here
    // the output should also be serialised despite
    // sending messages from two threads
    gOut.lines.shouldEqual(
        [
            "foobar",
            "toto",
            "last one from me",
            "what about me?",
            "seriously, what about me?",
            "final attempt",
            ]
        );
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly, Tid;
    import unit_threaded.should;

    resetFakeFiles;

    auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
    writerTid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    writerTid.send("foo\n", thisTid);

    auto otherTid = spawn(
        (Tid writerTid, Tid testTid) {
            writerTid.send("bar\n", thisTid);
            testTid.send(true); // synchronize with test tid
        },
        writerTid,
        thisTid);

    receiveOnly!bool; //wait for spawned thread to do its thing

    // from now on, we've send "foo\n" but not flushed
    // and the other tid has send "bar\n" and flushed

    writerTid.send(Flush(), thisTid);

    writerTid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    gOut.lines.shouldEqual(
        [
            "foo",
            ]
        );
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly, Tid;
    import unit_threaded.should;

    resetFakeFiles;

    auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
    writerTid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    writerTid.send("foo\n", thisTid);

    auto otherTid = spawn(
        (Tid writerTid, Tid testTid) {
            writerTid.send("bar\n", thisTid);
            writerTid.send(Flush(), thisTid);
            writerTid.send("baz\n", thisTid);
            testTid.send(true); // synchronize with test tid
        },
        writerTid,
        thisTid);

    receiveOnly!bool; //wait for spawned thread to do its thing

    // from now on, we've send "foo\n" but not flushed
    // and the other tid has send "bar\n", flushed, then "baz\n"

    writerTid.send(Flush(), thisTid);

    writerTid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    gOut.lines.shouldEqual(
        [
            "foo",
            "bar",
            ]
        );
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly, Tid;
    import unit_threaded.should;

    resetFakeFiles;

    auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
    writerTid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    writerTid.send("foo\n", thisTid);

    auto otherTid = spawn(
        (Tid writerTid, Tid testTid) {
            writerTid.send("bar\n", thisTid);
            testTid.send(true); // synchronize with test tid
            receiveOnly!bool; // wait for test thread to flush and give up being the primary thread
            writerTid.send("baz\n", thisTid);
            writerTid.send(Flush(), thisTid);
            testTid.send(true);
        },
        writerTid,
        thisTid);

    receiveOnly!bool; //wait for spawned thread to do its thing

    // from now on, we've send "foo\n" but not flushed
    // and the other tid has send "bar\n" and flushed

    writerTid.send(Flush(), thisTid);

    otherTid.send(true); // tell it to continue
    receiveOnly!bool;

    // now the other thread should be the main thread and prints out its partial output ("bar")
    // and what it sent afterwards in order

    writerTid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    gOut.lines.shouldEqual(
        [
            "foo",
            "bar",
            "baz",
        ]
    );
}

unittest {
    import std.concurrency: spawn, thisTid, send, receiveOnly;
    import std.range: iota;
    import std.parallelism: parallel;
    import std.algorithm: map, canFind;
    import std.array: array;
    import std.conv: text;
    import unit_threaded.should;

    resetFakeFiles;

    auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
    writerTid.send(ThreadWait());
    receiveOnly!ThreadStarted;

    string textFor(int i, int j) {
        return text("i_", i, "_j_", j);
    }

    enum numThreads = 100;
    enum numMessages = 5;

    foreach(i; numThreads.iota.parallel) {
        foreach(j; 0 .. numMessages) {
            writerTid.send(textFor(i, j) ~ "\n", thisTid);
        }
        writerTid.send(Flush(), thisTid);
    }


    writerTid.send(ThreadFinish());
    receiveOnly!ThreadEnded;

    foreach(i; 0 .. numThreads) {
        const messages = numMessages.iota.map!(j => textFor(i, j)).array;
        if(!gOut.lines.canFind(messages))
            throw new Exception(text("Could not find ", messages, " in:\n", gOut.lines));
    }
}
