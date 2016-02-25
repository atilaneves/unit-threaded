import unit_threaded.runtime;
import unit_threaded.dub;
import std.algorithm;
import std.array;
import std.stdio;
import std.getopt;



int main(string[] args) {
    try {
        auto options = getGenUtOptions(args);
        if(options.earlyReturn) return 0;

        dubify(options);
        writeUtMainFile(options);
        return 0;
    } catch(Exception ex) {
        stderr.writeln("Error: ", ex.msg);
        return 1;
    }
}
