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

    private void escCode(string code) {
        write(code);
        stdout.flush();
    }

    private string getEscFunc(string colour) {
        return q{void esc} ~ colour ~ "() {\n" ~
               `    if(_useEscCodes) escCode(_escCodes["` ~ colour ~ `"]);` ~
               "\n}";
    }

    private string getWriteFunc(string colour) {
        return q{void writeln} ~ colour ~ "(string str) {" ~
                   "esc" ~ colour ~ "();" ~ //e.g. escRed();
                   "writeln(str);" ~
                   "escCancel();" ~
               "}";
    }

    private string getEscAndWrite(string colour) {
        return getEscFunc(colour) ~ getWriteFunc(colour);
    }

    mixin(getEscFunc("Cancel"));
    mixin(getEscAndWrite("Red"));
    mixin(getEscAndWrite("Green"));

} else {
    void escGreen()  { }
    void escRed()    { }
    void escCancel() { }
}
