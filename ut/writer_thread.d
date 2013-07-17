module ut.writer_thread;

import std.concurrency;
import std.stdio;

void writeInThread() {
    auto done = false;

    while(!done) {
        string output;
        receive(
            (string msg) {
                output ~= msg;
            },
            (Tid tid) {
                done = true;
            },
            (OwnerTerminated trm) {
                done = true;
            }
        );
        write(output);
    }
    stdout.flush();
}
