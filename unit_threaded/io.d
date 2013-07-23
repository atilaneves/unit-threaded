/**
 * IO related functions
 */

module unit_threaded.io;


import std.exception;
import std.conv;


private bool _debugOutput = false; ///whether or not to print debug messages


package void enableDebugOutput() nothrow {
    _debugOutput = true;
}

package bool isDebugOutputEnabled() nothrow {
    return _debugOutput;
}


/**
 * Not a real exception. This a hack in order to enable test functions
 * (not classes) to add to the TestCase instance _output in a "thread-safe"
 * manner (i.e. no overlapped outputs)
 */
package class DebugOutputException: Exception {
    this(T...)(T args) {
        super(text(args));
    }
}
/**
 * Write if debug output was enabled.
 * Not thread-safe in the sense that it will get
 * printed out immediately and may overlap with
 * other output
 */
void writelnUt(T...)(T args) {
    if(_debugOutput) writeln(args);
}

/**
 * Generates coloured output on POSIX systems
 */
version(Posix) {
    import std.stdio;

    private bool _useEscCodes;
    private string[string] _escCodes;
    static this() {
        import core.sys.posix.unistd;
        _useEscCodes = isatty(stdout.fileno()) != 0;
        _escCodes = [ "Red": "\033[31;1m",
                      "Green": "\033[32;1m",
                      "Cancel": "\033[0;;m" ];
    }

    private void escCode(string colour) {
        if(_useEscCodes) {
            write(_escCodes[colour]);
            stdout.flush();
        }
    }

    private string getWriteFunc(string colour) {
        return q{void writeln} ~ colour ~ "(T...)(T elts) {" ~ //e.g. void writelnRed(T...)(T elts) {
                   `escCode("` ~ colour ~ `");` ~ //e.g. escCode("Red");
                   "writeln(elts);" ~
                   `escCode("Cancel");` ~
               "}";
    }

    mixin(getWriteFunc("Red")); //writelnRed
    mixin(getWriteFunc("Green")); //writelnGreen

} else {
    void writelnRed(string str)   { writeln(str); }
    void writelnGreen(string str) { writeln(str); }
}
