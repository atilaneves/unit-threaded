module unit_threaded.behave;

import std.algorithm;
import std.array;
import std.format;
import std.path: baseName;
import std.range;
import std.string;
import unit_threaded.runner.io;
import unit_threaded.runner.testcase;

public:

alias background = printBehaveLine!"Background:";
alias given = printBehaveLine!"Given";
alias when = printBehaveLine!"When";
alias then = printBehaveLine!"Then";

private:

template printBehaveLine(string mode) {
    public void printBehaveLine(string file = __FILE__, size_t line = __LINE__, T...)(string message, T args) {
        // to save space, only use the filename.
        const stepLocation = format!"# %s:%s"(file.baseName, line);
        output.setBehaveLine(mode, format(message, args).intenseQuotes, stepLocation);
    }
    public void printBehaveLine(string fmt, string file = __FILE__, size_t line = __LINE__, T...)(T args) {
        // to save space, only use the filename.
        const stepLocation = format!"# %s:%s"(file.baseName, line);
        output.setBehaveLine(mode, format!fmt(args).intenseQuotes, stepLocation);
    }
}

string intenseQuotes(string text) {
    if (!_useEscCodes)
        // preserve `` in that case
        return text;
    // [a] => [a]
    // [a, b] => [a, b.intense]
    alias markIntense = pair => chain(pair.take(1), pair.drop(1).map!intense);
    return text.splitter('`').chunks(2).map!markIntense.joiner.join;
}


private size_t visibleLength(string ansiFormattedText) @safe {
    return ansiFormattedText
        .splitter("\033[")
        .mapExceptFirst!(fragment => fragment.find("m").drop(1))
        .map!"a.length"
        .sum;
}

@("visible length of string")
unittest {
    assert(("Hello " ~ green("World")).visibleLength == "Hello World".length);
}

private alias mapExceptFirst(alias pred) = range => chain(range.take(1), range.drop(1).map!pred);

class BehaveOutput: Output {
    this(Output next) {
        _next = next;
    }

    override void send(in string output) @safe {
        removePartial;
        _next.send(output);
    }

    override void flush(bool success) @safe {
        finishBehaveLine(success);
        // for spacing
        _next.send("\n");
        _next.flush(success);
    }

package:

    void setBehaveLine(Output, Location)(string mode, Output output, Location location) @safe
    {
        // for spacing
        if (_previousMode == "")
            _next.send("\n");
        finishBehaveLine(true);
        if (mode == _previousMode)
            mode = "And";
        else _previousMode = mode;
        _behaveLine = "\t" ~ mode.intense ~ " " ~ output;
        _longestLine = max(_longestLine, _behaveLine.visibleLength);
        _location = location;
        if (_useEscCodes) {
            // otherwise, we won't be able to erase it later
            _next.send(fullLine!noColor);
            _partialLine = true;
        }
    }

private:

    void finishBehaveLine(bool success) @safe {
        removePartial;
        if (_behaveLine) {
            _next.send((success ? fullLine!green : fullLine!red) ~ "\n");
            _behaveLine = null;
        }
    }

    void removePartial() @safe {
        if (_partialLine) {
            assert(_useEscCodes);
            // delete current line, carriage return.
            _next.send("\033[2K\r");
            _partialLine = false;
        }
    }

    final string fullLine(alias color)() @safe {
        const spacing = ((_longestLine + 7) / 8) * 8 + 3 - _behaveLine.visibleLength;
        return color(_behaveLine) ~ " ".repeat(spacing).join ~ _location;
    }

    // So we know to write 'Given...' 'And...'
    string _previousMode;
    // So we can flush on error, success or manual write.
    bool _partialLine;
    // Longest previous behave line output part.
    // Used for stable indenting of location.
    size_t _longestLine;
    string _behaveLine;
    string _location;
    Output _next;
}

private alias noColor = s => s;

// Return the current testcase's behave output.
// If the current output is not a behave output, make it one.
// TODO if there's another output wrapper like this, they'll
// compete for being the "outermost". Instead, provide a way to
// search the `next_` list.
BehaveOutput output() {
    import unit_threaded.runner.testcase: TestCase;

    auto writer = TestCase.currentTest.getWriter;
    if (auto behave = cast(BehaveOutput) writer)
        return behave;
    auto behave = new BehaveOutput(writer);
    TestCase.currentTest._output = behave;
    return behave;
}
