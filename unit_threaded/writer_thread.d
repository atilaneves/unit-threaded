module unit_threaded.writer_thread;

import std.concurrency;
import std.stdio;
import std.conv;

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

    void join() {
        _tid.send(thisTid); //tell it to join
        receiveOnly!Tid(); //wait for it to join
    }

private:

    this() {
        _tid = spawn(&writeInThread);
    }

    Tid _tid;

    static bool _instantiated; // Thread local
    __gshared WriterThread _instance;
}

void writeInThread() {
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
