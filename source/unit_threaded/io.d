/**
 * IO related functions
 */

module unit_threaded.io;

import std.concurrency: Tid;

/**
 * Write if debug output was enabled.
 */
void writelnUt(T...)(auto ref T args) {
    import unit_threaded.testcase: TestCase;
    if(isDebugOutputEnabled)
        TestCase.currentTest.getWriter.writeln(args);
}


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

private shared(bool) _debugOutput = false; ///print debug msgs?
private shared(bool) _forceEscCodes = false; ///use ANSI escape codes anyway?
bool _useEscCodes;
enum _escCodes = ["\033[31;1m", "\033[32;1m", "\033[33;1m", "\033[0;;m"];


static this() {
    version (Posix) {
        import std.stdio: stdout;
        import core.sys.posix.unistd: isatty;
        _useEscCodes = _forceEscCodes || isatty(stdout.fileno()) != 0;
    }
}


package void enableDebugOutput(bool value = true) nothrow {
    synchronized {
        _debugOutput = value;
    }
}

package bool isDebugOutputEnabled() nothrow @trusted {
    synchronized {
        return _debugOutput;
    }
}

package void forceEscCodes() nothrow {
    synchronized {
        _forceEscCodes = true;
    }
}

interface Output {
    void send(in string output) @safe;
    void flush() @safe;
}

private enum Colour {
    red,
    green,
    yellow,
    cancel,
}

private string colour(alias C)(in string msg) {
    return escCode(C) ~ msg ~ escCode(Colour.cancel);
}

private alias green = colour!(Colour.green);
private alias red = colour!(Colour.red);
private alias yellow = colour!(Colour.yellow);

/**
 * Send escape code to the console
 */
private string escCode(in Colour code) @safe {
    return _useEscCodes ? _escCodes[code] : "";
}


/**
 * Writes the args in a thread-safe manner.
 */
void write(T...)(Output output, auto ref T args) {
    import std.conv: text;
    output.send(text(args));
}

/**
 * Writes the args in a thread-safe manner and appends a newline.
 */
void writeln(T...)(Output output, auto ref T args) {
    write(output, args, "\n");
}

/**
 * Writes the args in a thread-safe manner in green (POSIX only).
 * and appends a newline.
 */
void writelnGreen(T...)(Output output, auto ref T args) {
    import std.conv: text;
    output.send(green(text(args) ~ "\n"));
}

/**
 * Writes the args in a thread-safe manner in red (POSIX only)
 * and appends a newline.
 */
void writelnRed(T...)(Output output, auto ref T args) {
    writeRed(output, args, "\n");
}

/**
 * Writes the args in a thread-safe manner in red (POSIX only).
 * and appends a newline.
 */
void writeRed(T...)(Output output, auto ref T args) {
    import std.conv: text;
    output.send(red(text(args)));
}

/**
 * Writes the args in a thread-safe manner in yellow (POSIX only).
 * and appends a newline.
 */
void writeYellow(T...)(Output output, auto ref T args) {
    import std.conv: text;
    output.send(yellow(text(args)));
}

/**
 * Thread to output to stdout
 */
class WriterThread: Output {

    import std.concurrency: Tid;

    /**
     * Returns a reference to the only instance of this class.
     */
    static WriterThread get() @trusted {
        if (!_instantiated) {
            synchronized {
                if (_instance is null) {
                    _instance = new WriterThread;
                }
                _instantiated = true;
            }
        }
        return _instance;
    }


    override void send(in string output) @safe {

        version(unitUnthreaded) {
            import std.stdio: write;
            write(output);
        } else {
            import std.concurrency: send, thisTid;
            () @trusted { _tid.send(output, thisTid); }();
        }
    }

    override void flush() @safe {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: send;
            () @trusted { _tid.send(Flush()); }();
        }
    }

    /**
     * Creates the singleton instance and waits until it's ready.
     */
    static void start() {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: send, receiveOnly;
            WriterThread.get._tid.send(ThreadWait());
            receiveOnly!ThreadStarted;
        }
    }

    /**
     * Waits for the writer thread to terminate.
     */
    void join() {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: send, receiveOnly;
            _tid.send(ThreadFinish()); //tell it to join
            receiveOnly!ThreadEnded;
            _instance = null;
            _instantiated = false;
        }
    }

private:

    this() {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: spawn, thisTid;
            import std.stdio: stdout, stderr;
            _tid = spawn(&threadWriter!(stdout, stderr), thisTid);
        }
    }


    Tid _tid;

    static bool _instantiated; /// Thread local
    __gshared WriterThread _instance;
}

unittest
{
    //make sure this can be brought up and down again
    WriterThread.get.join;
    WriterThread.get.join;
}

private struct ThreadWait{};
private struct ThreadFinish{};
private struct ThreadStarted{};
private struct ThreadEnded{};
private struct Flush{};

version (Posix) {
    enum nullFileName = "/dev/null";
} else {
    enum nullFileName = "NUL";
}

shared bool gBool;
private void threadWriter(alias OUT, alias ERR)(Tid tid)
{
    import std.concurrency: receive, send, OwnerTerminated;

    auto done = false;

    auto saveStdout = OUT;
    auto saveStderr = ERR;

    void restore() {
        saveStdout.flush();
        OUT = saveStdout;
        ERR = saveStderr;
    }

    scope (failure) restore;

    if (!isDebugOutputEnabled()) {
        OUT = typeof(OUT)(nullFileName, "w");
        ERR = typeof(ERR)(nullFileName, "w");
    }

    // the first thread to send output becomes the current
    // until that thread sends a Flush message no other thread
    // can print to stdout, so we store their outputs in the meanwhile
    string[Tid] outputs;
    Tid currentTid;

    void actuallyPrint(in string msg) {
        if(msg.length) saveStdout.write(msg);
    }

    while (!done) {
        receive(
            (string msg, Tid originTid) {
                if(currentTid == currentTid.init)
                    currentTid = originTid;

                if(currentTid == originTid)
                    actuallyPrint(msg);
                else
                    outputs[originTid] ~= msg;
            },
            (ThreadWait w) {
                tid.send(ThreadStarted());
            },
            (ThreadFinish f) {
                done = true;
            },
            (Flush f) {

                foreach(t, output; outputs)
                    actuallyPrint(output);

                outputs = outputs.init;
                currentTid = currentTid.init;
            },
            (OwnerTerminated trm) {
                done = true;
            }
        );
    }

    restore;
    tid.send(ThreadEnded());
}

version(testing_unit_threaded) {
    struct FakeFile {
        string fileName;
        string mode;
        string output;
        void flush() shared {}
        void write(string s) shared {
            output ~= s;
        }
        string[] lines() shared const @safe pure {
            import std.string: splitLines;
            return output.splitLines;
        }
    }
    shared FakeFile gOut;
    shared FakeFile gErr;
    void resetFakeFiles() {
        gOut = FakeFile("out", "mode");
        gErr = FakeFile("err", "mode");
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

    void otherThread(Tid writerTid, Tid testTid) {
        import std.concurrency: send, receiveOnly, OwnerTerminated, thisTid;
        try {
            writerTid.send("what about me?\n", thisTid);
            testTid.send(true);
            receiveOnly!bool;
            writerTid.send("seriously, what about me?\n", thisTid);
            testTid.send(true);
            receiveOnly!bool;
            writerTid.send("final attempt\n", thisTid);
            testTid.send(true);
            receiveOnly!bool;
        } catch(OwnerTerminated ex) {}
    }


    unittest {
        import std.concurrency: spawn, thisTid, send, receiveOnly;
        import unit_threaded.should;

        resetFakeFiles;

        auto writerTid = spawn(&threadWriter!(gOut, gErr), thisTid);
        writerTid.send(ThreadWait());
        receiveOnly!ThreadStarted;

        writerTid.send("foobar\n", thisTid);
        auto otherTid = spawn(&otherThread, writerTid, thisTid);
        receiveOnly!bool; //wait for otherThread 1st message
        writerTid.send("toto\n", thisTid);
        otherTid.send(true); //tell otherThread to continue
        receiveOnly!bool; //wait for otherThread 2nd message
        writerTid.send("last one from me\n", thisTid);
        writerTid.send(Flush()); //finish with our output
        otherTid.send(true); //finish
        receiveOnly!bool;

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
}
