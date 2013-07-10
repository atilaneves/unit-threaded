module ut.term;

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
    void writelnRed(string str)  { writeln(str); }
    void writelnGreen(string st) { writeln(str); }
}
