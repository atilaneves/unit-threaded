import unit_threaded.runtime;

void main(string[] args) {
    Options options;
    options.dirs = ["."];
    options.fileName = args.length > 1 ? args[1] : "bin/ut.d";
    writeUtMainFile(options);
}
