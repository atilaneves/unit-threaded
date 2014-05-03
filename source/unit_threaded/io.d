/**
 * IO related functions
 */

module unit_threaded.io;

import std.concurrency;
import std.stdio;
import std.conv;


private shared(bool) _debugOutput = false; ///whether or not to print debug messages
private shared(bool) _forceEscCodes = false; ///whether or not to use ANSI escape codes anyway


package void enableDebugOutput() {
    synchronized {
        _debugOutput = true;
    }
}

package bool isDebugOutputEnabled() {
    synchronized {
        return _debugOutput;
    }
}

package void forceEscCodes() {
    _forceEscCodes = true;
}

void addToOutput(ref string output, in string msg) {
    if(_debugOutput) {
        import std.stdio;
        writeln(msg);
    } else {
        output ~= msg;
    }
}

/**
 * Write if debug output was enabled. Not thread-safe in the sense that it
 * will get printed out immediately and may overlap with other output.
 */
void writelnUt(T...)(T args) {
    import std.stdio;
    if(_debugOutput) writeln("    ", args);
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


/**
 * Thread to output to stdout
 */
class WriterThread {
    static WriterThread get() {
        if(!_instantiated) {
            synchronized {
                if (_instance is null) {
                    _instance = new WriterThread;
                }
                _instantiated = true;
            }
        }
        return _instance;
    }

    void write(T...)(T args) {
        _tid.send(text(args));
    }

    void writeln(T...)(T args) {
        write(args, "\n");
    }

    void writelnGreen(T...)(T args) {
        _tid.send(green(text(args) ~ "\n"));
    }

    void writelnRed(T...)(T args) {
        _tid.send(red(text(args) ~ "\n"));
    }

    void writeRed(T...)(T args) {
        _tid.send(red(text(args)));
    }

    void writeYellow(T...)(T args) {
        _tid.send(yellow(text(args)));
    }

    void join() {
        _tid.send(thisTid); //tell it to join
        receiveOnly!Tid(); //wait for it to join
    }

private:

    this() {
        _tid = spawn(&threadWriter);
        _escCodes = [ "red": "\033[31;1m",
                      "green": "\033[32;1m",
                      "yellow": "\033[33;1m",
                      "cancel": "\033[0;;m" ];

        version(Posix) {
            import core.sys.posix.unistd;
            _useEscCodes = _forceEscCodes || isatty(stdout.fileno()) != 0;
        }
    }

    /**
     * Generates coloured output on POSIX systems
     */
    string green(in string msg) const {
        return escCode("green") ~ msg ~ escCode("cancel");
    }

    string red(in string msg) const {
        return escCode("red") ~ msg ~ escCode("cancel");
    }

    string yellow(in string msg) const {
        return escCode("yellow") ~ msg ~ escCode("cancel");
    }

    string escCode(in string code) const {
        return _useEscCodes ? _escCodes[code] : "";
    }


    Tid _tid;
    string[string] _escCodes;
    bool _useEscCodes;

    static bool _instantiated; // Thread local
    __gshared WriterThread _instance;
}

private void threadWriter() {
    auto done = false;
    Tid tid;

    auto saveStdout = stdout;
    auto saveStderr = stderr;

    if(!isDebugOutputEnabled()) {
        version(Posix) {
            enum nullFileName = "/dev/null";
        } else {
            enum nullFileName = "NUL";
        }

        stdout = File(nullFileName, "w");
        stderr = File(nullFileName, "w");
    }

    while(!done) {
        string output;
        receive(
            (string msg) {
                output ~= msg;
            },
            (Tid i) {
                done = true;
                tid = i;
            },
            (OwnerTerminated trm) {
                done = true;
            }
        );
        saveStdout.write(output);
    }
    saveStdout.flush();
    stdout = saveStdout;
    stderr = saveStderr;
    if(tid != Tid.init) tid.send(thisTid);
}
