/**
 * IO related functions
 */

module unit_threaded.io;

import std.concurrency;
import std.stdio;
import std.conv;


/**
 * Write if debug output was enabled. Not thread-safe in the sense that it
 * will get printed out immediately and may overlap with other output.
 * This is why the test runner forces single-threaded mode when debug mode
 * is selected.
 */
void writelnUt(T...)(T args)
{
    import std.stdio;
    if(_debugOutput) writeln("    ", args);
}

private shared(bool) _debugOutput = false; ///print debug msgs?
private shared(bool) _forceEscCodes = false; ///use ANSI escape codes anyway?


package void enableDebugOutput() nothrow
{
    synchronized
    {
        _debugOutput = true;
    }
}

package bool isDebugOutputEnabled() nothrow
{
    synchronized
    {
        return _debugOutput;
    }
}

package void forceEscCodes() nothrow
{
    synchronized
    {
        _forceEscCodes = true;
    }
}

/**
 * Adds to the test cases output so far or immediately prints
 */
package void addToOutput(ref string output, in string msg)
{
    if(_debugOutput)
    {
        import std.stdio;
        writeln(msg);
    }
    else
    {
        output ~= msg;
    }
}


package void utWrite(T...)(T args)
{
    WriterThread.get().write(args);
}

package void utWriteln(T...)(T args)
{
    WriterThread.get().writeln(args);
}

package void utWritelnGreen(T...)(T args)
{
    WriterThread.get().writelnGreen(args);
}

package void utWritelnRed(T...)(T args)
{
    WriterThread.get().writelnRed(args);
}

package void utWriteRed(T...)(T args)
{
    WriterThread.get().writeRed(args);
}

package void utWriteYellow(T...)(T args)
{
    WriterThread.get().writeYellow(args);
}


/**
 * Thread to output to stdout
 */
class WriterThread
{
    static WriterThread get()
    {
        if(!_instantiated)
        {
            synchronized
            {
                if (_instance is null)
                {
                    _instance = new WriterThread;
                }
                _instantiated = true;
            }
        }
        return _instance;
    }

    void write(T...)(T args)
    {
        _tid.send(text(args));
    }

    void writeln(T...)(T args)
    {
        write(args, "\n");
    }

    void writelnGreen(T...)(T args)
    {
        _tid.send(green(text(args) ~ "\n"));
    }

    void writelnRed(T...)(T args)
    {
        _tid.send(red(text(args) ~ "\n"));
    }

    void writeRed(T...)(T args)
    {
        _tid.send(red(text(args)));
    }

    void writeYellow(T...)(T args)
    {
        _tid.send(yellow(text(args)));
    }

    static void start()
    {
        WriterThread.get._tid.send(true, thisTid);
        receiveOnly!bool; //wait for it to start
    }

    void join()
    {
        _tid.send(thisTid); //tell it to join
        receiveOnly!Tid(); //wait for it to join
        _instance = null;
        _instantiated = false;
    }

private:

    this()
    {
        _tid = spawn(&threadWriter);
        _escCodes = [ "red": "\033[31;1m",
                      "green": "\033[32;1m",
                      "yellow": "\033[33;1m",
                      "cancel": "\033[0;;m" ];

        version(Posix)
        {
            import core.sys.posix.unistd;
            _useEscCodes = _forceEscCodes || isatty(stdout.fileno()) != 0;
        }
    }

    /**
     * Generate green coloured output on POSIX systems
     */
    string green(in string msg) const
    {
        return escCode("green") ~ msg ~ escCode("cancel");
    }

    /**
     * Generate red coloured output on POSIX systems
     */
    string red(in string msg) const
    {
        return escCode("red") ~ msg ~ escCode("cancel");
    }

    /**
     * Generate yellow coloured output on POSIX systems
     */
    string yellow(in string msg) const
    {
        return escCode("yellow") ~ msg ~ escCode("cancel");
    }

    /**
     * Send escape code to the console
     */
    string escCode(in string code) const
    {
        return _useEscCodes ? _escCodes[code] : "";
    }


    Tid _tid;
    string[string] _escCodes;
    bool _useEscCodes;

    static bool _instantiated; /// Thread local
    __gshared WriterThread _instance;
}

private void threadWriter()
{
    auto done = false;
    Tid _tid;

    auto saveStdout = stdout;
    auto saveStderr = stderr;

    if(!isDebugOutputEnabled())
    {
        version(Posix)
        {
            enum nullFileName = "/dev/null";
        }
        else
        {
            enum nullFileName = "NUL";
        }

        stdout = File(nullFileName, "w");
        stderr = File(nullFileName, "w");
    }

    while(!done)
    {
        string output;
        receive(
            (string msg) {
                output ~= msg;
            },
            (bool, Tid tid) {
                //another thread is waiting for confirmation
                //that we started, let them know it's ok to proceed
                tid.send(true);
            },
            (Tid tid) {
                done = true;
                _tid = tid;
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
    if(_tid != Tid.init) _tid.send(thisTid);
}


unittest {
    //make sure this can be brought up and down again
    WriterThread.get.join;
    WriterThread.get.join;
}
