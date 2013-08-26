unit-threaded
=============


Multi-threaded unit test framework for D. Based on similar work for
[C++11](https://bitbucket.org/atilaneves/unit-thread).

"But doesn't D have built-in `unittest` blocks"? Yes, and they're
massively useful. Even short scripts can benefit from them with 0
effort and setup. In fact, I use them to test this library. However,
for larger projects it lacks some functionality:

1. If all tests pass, great. If one fails, it's hard to know why.
2. The only tool is assert, and you have to write your own assert
   messages (no assertEqual, assertNull, etc.)
3. No possibility to run just one particular test
4. Only runs in one thread.

So I wrote this library in and for a language with built-in support
for unit tests. Its goals are:

1. To run concurrently (by default) for maximal speed and turnaround
for TDD
2. To make it easy to write tests (functions as test cases)
3. No test registration. Tests are discovered with D's compile-time
reflection
4. Support for built-in `unittest` blocks
5. To be able to run specific tests or group of tests via
the command-line
6. Suppress tested code stdio and stderr output by default (important
when running in multiple threads).
7. Have a special mode that only works when using a single thread
under which tested code output is turned back on, as well as special
writelnUt debug messages.
8. Ability to temporarily hide tests from being run by default whilst
stil being able to run them

The library is all in the `unit_threaded` package. There are two
example programs in the [`example`](example/) folder, one with passing
unit tests and the other failing, to show what the output looks like
in each case.

The built-in D unittest blocks are included automatically, as seen in
the output of both example programs
(`example.tests.pass_tests.unittest` and its homologue in
[`example_fail`](example/example_fail)).

The easiest way to run tests is by doing what the example code does:
calling `runTests()` in [`runner.d`](unit_threaded/runner.d) with
the modules containing the tests as compile-time arguments. This can
be done as symbols or strings, and the two approaches are shown in
the examples.

There is no need to register tests. The registration is implicit by
deriving from `TestCase` and overriding `test()` *or* by writing a
function whose name is in camel-case and begins with "test"
(e.g. `testFoo()`, `testGadget()`).  Specify which modules contain
tests when calling `runTests()` and that's it.

`TestCase` also has support for `setup()` and `shutdown()`, child
classes need only override the appropriate functions(s).

Don't like the algorithm for registering tests? Not a problem. The
attributes `@UnitTest` and `@DontTest` can be used to opt-in or
opt-out. These are used in the examples.

Tests can also be hidden with the `@HiddenTest` attribute. This means
that particular test doesn't get run by default but can still be run
by passing its name as a command-line argument.

Since D packages are just directories and there is no way to read the
filesystem at compile-time, there is no way to automatically add all
tests in packages(s).  To mitigate this and avoid having to manually
write the name of all the modules containing tests, a utility called
[`run_tests_in_dir`](utils/run_tests_in_dir.d) can be used to generate
a source file automatically. To use it, pass as the 1st argument a
file name to generate, and the rest of the arguments should be
directory names. It will automatically generate a file and execute it
with rdmd, then print the result.

There is support for debug prints in the tests with the `-d` switch.
This is only supported in single-threaded mode (`-s`). Setting `-d`
without `-s` will trigger a warning followed by the forceful use of
`-s`.  TestCases and test functions can print debug output with the
function `writelnUt` available [here](unit_threaded/io.d).
