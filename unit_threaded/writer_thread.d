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
    }

    Tid _tid;

    static bool _instantiated; // Thread local
    __gshared WriterThread _instance;
}

private void threadWriter() {
    auto done = false;
    Tid tid;

    auto saveStdout = stdout;
    scope(exit) stdout = saveStdout;
    auto saveStderr = stderr;
    scope(exit) stderr = saveStderr;

    stdout = File("/dev/null", "w");
    stderr = File("/dev/null", "w");

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
    if(tid != Tid.init) tid.send(thisTid);
}
