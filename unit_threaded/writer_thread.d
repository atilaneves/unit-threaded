module unit_threaded.writer_thread;

/**
 * Thread to output to stdout
 */

import std.concurrency;
import std.stdio;

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
