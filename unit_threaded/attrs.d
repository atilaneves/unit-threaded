module unit_threaded.attrs;

enum UnitTest; //opt-in to registration
enum DontTest; //opt-out of registration
enum HiddenTest; //hide test. Not run by default but can be run.
enum SingleThreaded; //run tests in the module in one thread
