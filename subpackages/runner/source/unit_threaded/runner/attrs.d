/**
   UDAs for decorating tests.
 */
module unit_threaded.runner.attrs;

import unit_threaded.from;

enum Serial; //run tests in the module in one thread / serially

alias SingleThreaded = Serial;

///Hide test. Not run by default but can be run.
struct HiddenTest {
    string reason;
}

/// The suite fails if the test passes.
struct ShouldFail {
    string reason;
}

/// The suite fails unless the test throws T
struct ShouldFailWith(T: Throwable) {
    alias Type = T;
    string reason;
}

/// Associate a name with a unittest block.
struct Name {
    string value;
}

/// Associates one or more tags with the test
struct Tags {
    this(string[] values...) { this.values = values;}
    this(string[] values) { this.values =  values; }
    this(string value)    { this.values = [value]; }
    string[] values;
}


enum Setup;
enum Shutdown;

struct Flaky {
    /// the number of times to run the test
    enum defaultRetries = 10;
    int retries = defaultRetries;
}
