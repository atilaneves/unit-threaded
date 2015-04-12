module unit_threaded.attrs;

/**
 * Associate a name with a unittest block.
 */
struct Name
{
    string value;
}

enum SingleThreaded; ///run all unittests in the module in one thread

/**
 * The suite fails if the test passes.
 */
struct ShouldFail
{
    string reason;
}

/**
 * Hide test. Not run by default but can be run by specifying its name
 * on the command-line.
 */
struct HiddenTest
{
    string reason;
}
