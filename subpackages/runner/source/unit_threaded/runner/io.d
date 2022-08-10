/**
 * IO related functions
 */

module unit_threaded.runner.io;

import unit_threaded.from;

/**
 * Write if debug output was enabled.
 */
void writelnUt(T...)(auto ref T args) {
    debug {
        import unit_threaded.runner.testcase: TestCase;
        if(isDebugOutputEnabled)
            TestCase.currentTest.getWriter.writeln(args);
    }
}



private shared(bool) _debugOutput = false; ///print debug msgs?
private shared(bool) _forceEscCodes = false; ///use ANSI escape codes anyway?
package(unit_threaded) shared(bool) _useEscCodes;


version (Windows) {
    import core.sys.windows.winbase: GetStdHandle, STD_OUTPUT_HANDLE, INVALID_HANDLE_VALUE;
    import core.sys.windows.wincon: GetConsoleMode, SetConsoleMode, ENABLE_VIRTUAL_TERMINAL_PROCESSING;

    private __gshared uint originalConsoleMode;

    private bool enableEscapeCodes(bool initialize = false) {
        auto handle = GetStdHandle(STD_OUTPUT_HANDLE);
        if (!handle || handle == INVALID_HANDLE_VALUE)
            return false;

        uint mode;
        if (!GetConsoleMode(handle, &mode))
            return false;

        if (initialize)
            originalConsoleMode = mode;

        if (mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING)
            return true; // already enabled

        return SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0;
    }

    package void tryEnableEscapeCodes() {
        if (_useEscCodes)
            enableEscapeCodes();
    }
}

private extern (C) int isatty(int) nothrow; // POSIX, MSVC and DigitalMars C runtime

shared static this() {
    import std.stdio: stdout;

    _useEscCodes = _forceEscCodes || isatty(stdout.fileno()) != 0;

    // Windows: if _useEscCodes == true, enable ANSI escape codes for the stdout console
    //          (supported since Win10 v1511)
    version (Windows)
        if (_useEscCodes)
            _useEscCodes = enableEscapeCodes(/*initialize=*/true);
}

// Windows: restore original console mode on shutdown
version (Windows) {
    shared static ~this() {
        if (_useEscCodes && !(originalConsoleMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING))
            SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), originalConsoleMode);
    }
}


void enableDebugOutput(bool value = true) nothrow {
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
    void flush(bool success) @safe;
}

private enum Effect {
    red,
    green,
    yellow,
    intense,
    defaultColour,
    defaultIntensity,
}

private string wrapEffect(Effect effect)(in string msg) {
    static if (effect == Effect.intense)
        return escCode(effect) ~ msg ~ escCode(Effect.defaultIntensity);
    else
        return escCode(effect) ~ msg ~ escCode(Effect.defaultColour);
}

package(unit_threaded) alias green = wrapEffect!(Effect.green);
package(unit_threaded) alias red = wrapEffect!(Effect.red);
package(unit_threaded) alias yellow = wrapEffect!(Effect.yellow);
package(unit_threaded) alias intense = wrapEffect!(Effect.intense);

/**
 * Send escape code to the console
 */
private string escCode(in Effect effect) @safe {
    if (!_useEscCodes) return "";
    final switch (effect) {
        case Effect.red: return "\033[31m";
        case Effect.green: return "\033[32m";
        case Effect.yellow: return "\033[33m";
        case Effect.intense: return "\033[1m";
        case Effect.defaultColour: return "\033[39m";
        case Effect.defaultIntensity: return "\033[22m";
    }
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
    output.send(text(args).green.intense ~ "\n");
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
    output.send(text(args).red.intense);
}

/**
 * Writes the args in a thread-safe manner in yellow (POSIX only).
 * and appends a newline.
 */
void writeYellow(T...)(Output output, auto ref T args) {
    import std.conv: text;
    output.send(text(args).yellow.intense);
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
        import std.concurrency: initOnce;
        static __gshared WriterThread instance;
        return initOnce!instance(new WriterThread);
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

    override void flush(bool success) @safe {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: send, thisTid;
            () @trusted { _tid.send(Flush(), thisTid); }();
        }
    }


private:

    this() {
        version(unitUnthreaded) {}
        else {
            import std.concurrency: spawn, thisTid, receiveOnly, send;
            import std.stdio: stdout, stderr;
            _tid = spawn(&threadWriter!(stdout, stderr), thisTid);
            _tid.send(ThreadWait());
            receiveOnly!ThreadStarted;
        }
    }


    Tid _tid;
}


struct ThreadWait{};
struct ThreadFinish{};
struct ThreadStarted{};
struct ThreadEnded{};
struct Flush{};

version (Posix) {
    enum nullFileName = "/dev/null";
} else {
    enum nullFileName = "NUL";
}


void threadWriter(alias OUT, alias ERR)(from!"std.concurrency".Tid tid)
{
    import std.concurrency: receive, send, OwnerTerminated, Tid;

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

    void actuallyPrint(in string msg) {
        if(msg.length) {
            saveStdout.write(msg);
            // ensure partial lines are already printed.
            saveStdout.flush();
        }
    }

    // the first thread to send output becomes the current
    // until that thread sends a Flush message no other thread
    // can print to stdout, so we store their outputs in the meanwhile
    static struct ThreadOutput {
        string currentOutput;
        string[] outputs;

        void store(in string msg) {
            currentOutput ~= msg;
        }

        void flush() {
            outputs ~= currentOutput;
            currentOutput = "";
        }
    }
    ThreadOutput[Tid] outputs;

    Tid currentTid;

    while (!done) {
        receive(
            (string msg, Tid originTid) {

                if(currentTid == currentTid.init) {
                    currentTid = originTid;

                    // it could be that this thread became the current thread but had output not yet printed
                    if(originTid in outputs) {
                        actuallyPrint(outputs[originTid].currentOutput);
                        outputs[originTid].currentOutput = "";
                    }
                }

                if(currentTid == originTid)
                    actuallyPrint(msg);
                else {
                    if(originTid !in outputs) outputs[originTid] = typeof(outputs[originTid]).init;
                    outputs[originTid].store(msg);
                }
            },
            (ThreadWait w) {
                tid.send(ThreadStarted());
            },
            (ThreadFinish f) {
                done = true;
            },
            (Flush f, Tid originTid) {

                if(originTid in outputs) outputs[originTid].flush;

                if(currentTid != currentTid.init && currentTid != originTid)
                    return;

                foreach(_, ref threadOutput; outputs) {
                    foreach(o; threadOutput.outputs)
                        actuallyPrint(o);
                    threadOutput.outputs = [];
                }

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
