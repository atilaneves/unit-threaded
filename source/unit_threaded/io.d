/**
 * IO related functions
 */

module unit_threaded.io;

import unit_threaded.from;

/**
 * Write if debug output was enabled.
 */
void writelnUt(T...)(auto ref T args) {
    debug {
        import unit_threaded.testcase: TestCase;
        if(isDebugOutputEnabled)
            TestCase.currentTest.getWriter.writeln(args);
    }
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

    override void flush() @safe {
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
        if(msg.length) saveStdout.write(msg);
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

                foreach(tid, ref threadOutput; outputs) {
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
