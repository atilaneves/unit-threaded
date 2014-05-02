module unit_threaded.attrs;

enum UnitTest; //opt-in to registration
enum DontTest; //opt-out of registration
enum SingleThreaded; //run tests in the module in one thread

//hide test. Not run by default but can be run.
struct HiddenTest {
    string reason;
}

//suite fails if the test passes
struct ShouldFail {
    string reason;
}

package template TypeOf(alias T) {
    static if(__traits(compiles, typeof(T))) {
        alias TypeOf = typeof(T);
    } else {
        alias TypeOf = T;
    }
}

package template isAHiddenStruct(alias T) {
    enum isAHiddenStruct = is(TypeOf!T == HiddenTest);
}

package template isAShouldFailStruct(alias T) {
    enum isAShouldFailStruct = is(TypeOf!T == ShouldFail);
}
