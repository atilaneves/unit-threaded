import unit_threaded;

int main(string[] args) {
    return args.runTests!("foo.bar.baz", "foo.bar");
}
