module unit_threaded.attrs;

enum UnitTest; //opt-in to registration
enum DontTest; //opt-out of registration
enum SingleThreaded; //run tests in the module in one thread

struct HiddenTest(string reason) {} //hide test. Not run by default but can be run.
struct ShouldFail(string reason) {} //suite fails if the test passes

package enum isAHiddenStruct(T) = is(T:HiddenTest!S, string S);
package enum isAShouldFailStruct(T) = is(T:ShouldFail!S, string S);
