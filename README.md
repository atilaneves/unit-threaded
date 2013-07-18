unit-threaded
=============


Multi-threaded unit test framework for D. Based on similar work for
[C++11](https://bitbucket.org/atilaneves/unit-thread).

The library is all in the `unit_threaded` package. There are two
example programs in the [`example`](example/) folder, one with passing unit tests
and the other failing, to show what the output looks like in each case.

There is support for the built-in D unittest blocks as well, as seen
in the output of [`example_fail`](example/example_fail.d). They are included
automatically.

The easiest way to run tests is by doing what the example code does:
calling `runTests()` in [`runner.d`](unit_threaded/runner.d) with
the modules containing the tests as compile-time arguments. This can
be done as symbols or strings, and the two approaches are shown in
the examples.

There is no need to register tests. The registration is implicit by
deriving from `TestCase` and overriding `test()` or by writing a function
whose name is in camel-case and begins with test (e.g. `testFoo()`, `testGadget()`).
Specify which modules contain tests when calling `runTests()` and that's it.

TestCase also has support for `setup()` and `shutdown()`, child classes need only
override the appropriate functions(s).

Since D packages are just directories and there is no way to read the filesystem
at compile-time, there is no way to automatically add all tests in packages(s).
To mitigate this and avoid having to manually write the name of all the modules
containing tests, a utility called [`finder`](unit_threaded/finder.d) can be
used to generate a source file automatically. To use it, pass a 1st argument
a file name to generate, and the rest of the arguments should be directory
names. It will automatically generate a file and execute it with rdmd,
then print the result.


MAYBE:

- Lazy expressions to get better failure messages?
- Random reordering of tests in single-threaded mode?
- Split code to avoid bloat and decrease linking time?
