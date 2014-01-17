/**
 * IO related functions
 */

module unit_threaded.io;

import unit_threaded.writer_thread;


private shared(bool) _debugOutput = false; ///whether or not to print debug messages


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
    if(_debugOutput) writeln(args);
}
