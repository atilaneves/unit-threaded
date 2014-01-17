module unit_threaded.writer_thread;

import unit_threaded.io;
import std.concurrency;
import std.stdio;
import std.conv;


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

    void join() {
        _tid.send(thisTid); //tell it to join
        receiveOnly!Tid(); //wait for it to join
    }

private:

    this() {
        _tid = spawn(&threadWriter);
        _escCodes = [ "red": "\033[31;1m",
                      "green": "\033[32;1m",
                      "cancel": "\033[0;;m" ];

        version(Posix) {
            import core.sys.posix.unistd;
            _useEscCodes = isatty(stdout.fileno()) != 0;
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
