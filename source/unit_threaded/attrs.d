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

/**
 * Utility to allow checking UDAs for types
 * regardless of whether the template parameter
 * is or has a type
 */
package template TypeOf(alias T) {
    static if(__traits(compiles, typeof(T))) {
        alias TypeOf = typeof(T);
    } else {
        alias TypeOf = T;
    }
}

package enum isHiddenTest(alias T) = is(TypeOf!T == HiddenTest);
package enum isShouldFail(alias T) = is(TypeOf!T == ShouldFail);

struct Name {
    string value;
}
