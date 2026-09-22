import core.thread : Thread;
import core.time : MonoTime, dur;
import std.exception : enforce;
import std.file : thisExePath;
import std.process : spawnProcess, tryWait, kill, wait;
import std.stdio : stdout, stderr, writeln;
import unit_threaded.runtime.dub : getDubInfo;

void main(string[] args) {
    if(args.length > 1 && args[1] == "describe") {
        describe();
        return;
    }

    if(args.length > 1 && args[1] == "read") {
        auto info = getDubInfo(false, thisExePath());
        enforce(info.packages.length == 0, "Unexpected dub describe result");
        return;
    }

    // Isolate the reader so a regression fails instead of hanging the test suite.
    auto reader = spawnProcess([thisExePath(), "read"]);
    scope(exit) {
        if(!tryWait(reader).terminated)
            kill(reader);
        wait(reader);
    }

    auto deadline = MonoTime.currTime + dur!"seconds"(10);
    while(!tryWait(reader).terminated) {
        enforce(MonoTime.currTime < deadline,
                "getDubInfo timed out while draining stdout and stderr");
        Thread.sleep(dur!"msecs"(10));
    }
    enforce(wait(reader) == 0, "getDubInfo failed to parse dub describe output");
    writeln("Concurrent dub output regression test passed");
}

void describe() {
    import std.array : replicate;

    // Fill stderr before closing stdout: sequential readers deadlock here.
    // Both streams exceed typical pipe capacities, and stderr is not JSON.
    auto warnings = "warning\n".replicate(512);
    auto whitespace = " ".replicate(4096);
    foreach(i; 0 .. 256)
        stderr.write(warnings);
    stderr.flush();
    foreach(i; 0 .. 256)
        stdout.write(whitespace);
    stdout.write(`{"packages":[]}`);
    stdout.flush();
}
