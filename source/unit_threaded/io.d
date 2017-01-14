/**
 * IO related functions
 */

module unit_threaded.io;

import std.concurrency;
import std.stdio;
import std.conv;

/**
 * Write if debug output was enabled. Not thread-safe in the sense that it
 * will get printed out immediately and may overlap with other output.
 * This is why the test runner forces single-threaded mode when debug mode
 * is selected.
 */
void writelnUt(T...)(T args) {
    import std.conv: text;
    import unit_threaded: TestCase;
    TestCase.currentTest._output ~= text(args);
}


unittest {
    import unit_threaded.should;
    import unit_threaded.testcase: TestCase;
    import unit_threaded.reflection: TestData;
    import unit_threaded.factory: createTestCase;
    import std.traits: fullyQualifiedName;
    import std.string: split;

    enableDebugOutput;
    scope(exit) enableDebugOutput(false);

    class TestOutput: Output {
        string output;
        override void send(in string output) {
            import std.conv: text;
            this.output ~= output;
        }
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

    writer.output.split("\n").shouldEqual(
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

package bool isDebugOutputEnabled() nothrow {
    synchronized {
        return _debugOutput;
    }
}

package void forceEscCodes() nothrow {
    synchronized {
        _forceEscCodes = true;
    }
}


package void utWrite(T...)(T args) {
    WriterThread.get().write(args);
}

package void utWriteln(T...)(T args) {
    WriterThread.get().writeln(args);
}

package void utWritelnGreen(T...)(T args) {
    WriterThread.get().writelnGreen(args);
}

package void utWritelnRed(T...)(T args) {
    WriterThread.get().writelnRed(args);
}

package void utWriteRed(T...)(T args) {
    WriterThread.get().writeRed(args);
}

package void utWriteYellow(T...)(T args) {
    WriterThread.get().writeYellow(args);
}

interface Output {
    void send(in string output);
}

private enum Color {
    red,
    green,
    yellow,
    cancel,
}

/**
 * Generate green coloured output on POSIX systems
 */
private string green(in string msg) @safe {
    return escCode(Color.green) ~ msg ~ escCode(Color.cancel);
}

/**
 * Generate red coloured output on POSIX systems
 */
private string red(in string msg) @safe {
    return escCode(Color.red) ~ msg ~ escCode(Color.cancel);
}

/**
 * Generate yellow coloured output on POSIX systems
 */
private string yellow(in string msg) @safe {
    return escCode(Color.yellow) ~ msg ~ escCode(Color.cancel);
}

/**
 * Send escape code to the console
 */
private string escCode(in Color code) @safe {
    return _useEscCodes ? _escCodes[code] : "";
}


/**
 * Writes the args in a thread-safe manner.
 */
void write(T...)(Output output, T args) {
    output.send(text(args));
}

/**
 * Writes the args in a thread-safe manner and appends a newline.
 */
void writeln(T...)(Output output, T args) {
    write(output, args, "\n");
}

/**
 * Writes the args in a thread-safe manner in green (POSIX only).
 * and appends a newline.
 */
void writelnGreen(T...)(Output output, T args) {
    output.send(green(text(args) ~ "\n"));
}

/**
 * Writes the args in a thread-safe manner in red (POSIX only)
 * and appends a newline.
 */
void writelnRed(T...)(Output output, T args) {
    output.send(red(text(args) ~ "\n"));
}

/**
 * Writes the args in a thread-safe manner in red (POSIX only).
 * and appends a newline.
 */
void writeRed(T...)(Output output, T args) {
    output.send(red(text(args)));
}

/**
 * Writes the args in a thread-safe manner in yellow (POSIX only).
 * and appends a newline.
 */
void writeYellow(T...)(Output output, T args) {
    output.send(yellow(text(args)));
}

/**
 * Thread to output to stdout
 */
class WriterThread: Output {
    /**
     * Returns a reference to the only instance of this class.
     */
    static WriterThread get() {
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

    override void send(in string output) {
        _tid.send(output);
    }

    /**
     * Creates the singleton instance and waits until it's ready.
     */
    static void start() {
        WriterThread.get._tid.send(true, thisTid);
        receiveOnly!bool; //wait for it to start
    }

    /**
     * Waits for the writer thread to terminate.
     */
    void join() {
        _tid.send(thisTid); //tell it to join
        receiveOnly!Tid(); //wait for it to join
        _instance = null;
        _instantiated = false;
    }

private:

    this() {
        _tid = spawn(&threadWriter);
    }


    Tid _tid;

    static bool _instantiated; /// Thread local
    __gshared WriterThread _instance;
}

private void threadWriter()
{
    auto done = false;
    Tid _tid;

    auto saveStdout = stdout;
    auto saveStderr = stderr;

    scope (exit) {
        saveStdout.flush();
        stdout = saveStdout;
        stderr = saveStderr;
    }

    if (!isDebugOutputEnabled()) {
        version (Posix) {
            enum nullFileName = "/dev/null";
        } else {
            enum nullFileName = "NUL";
        }

        stdout = File(nullFileName, "w");
        stderr = File(nullFileName, "w");
    }

    while (!done) {
        string output;
        receive(
            (string msg) {
                output ~= msg;
            },
           (bool, Tid tid) {
               //another thread is waiting for confirmation
               //that we started, let them know it's ok to proceed
                tid.send(true);
            },
            (Tid tid) {
                done = true;
                _tid = tid;
            },
            (OwnerTerminated trm) {
                done = true;
            }
        );
        saveStdout.write(output);
    }
    if (_tid != Tid.init)
        _tid.send(thisTid);
}

unittest
{
    //make sure this can be brought up and down again
    WriterThread.get.join;
    WriterThread.get.join;
}
