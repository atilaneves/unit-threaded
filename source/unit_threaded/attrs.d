module unit_threaded.attrs;

enum UnitTest; //opt-in to registration
enum DontTest; //opt-out of registration
enum SingleThreaded; //run tests in the module in one thread

///Hide test. Not run by default but can be run.
struct HiddenTest {
    string reason;
}

/// The suite fails if the test passes.
struct ShouldFail {
    string reason;
}

/// Associate a name with a unittest block.
struct Name {
    string value;
}
