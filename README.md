unit-threaded
=============
[![Build Status](https://travis-ci.org/atilaneves/unit-threaded.png?branch=master)](https://travis-ci.org/atilaneves/unit-threaded)

Multi-threaded unit test framework for D. Based on similar work for
[C++11](https://bitbucket.org/atilaneves/unit-thread).

Reasoning
---------

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

1. To run in parallel (by default) for maximal speed and turnaround
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

Usage
-----

The library is all in the `unit_threaded` package. There are two
example programs in the [`example`](example/) folder, one with passing
unit tests and the other failing, to show what the output looks like
in each case. Because of the way D packages work, they must be run
from the top-level directory of the repository.

The built-in D unittest blocks are included automatically, as seen in
the output of both example programs
(`example.tests.pass_tests.unittest` and its homologue in
[`example_fail`](example/example_fail)). A name will be automatically
generated for them. The user can specify a name by decorating them
with a string UDA or the included `@Name` UDA.

The easiest way to run tests is by doing what the example code does:
calling `runTests()` in [`runner.d`](unit_threaded/runner.d) with
the modules containing the tests as compile-time arguments. This can
be done as symbols or strings, and the two approaches are shown in
the examples.

There is no need to register tests. The registration is implicit by
deriving from `TestCase` and overriding `test()` *or* by writing a
function whose name is in camel-case and begins with "test"
(e.g. `testFoo()`, `testGadget()`).  Specify which modules contain
tests when calling `runTests()` and that's it. Private functions
are skipped.

`TestCase` also has support for `setup()` and `shutdown()`, child
classes need only override the appropriate functions(s).

Don't like the algorithm for registering tests? Not a problem. The
attributes `@UnitTest` and `@DontTest` can be used to opt-in or
opt-out. These are used in the examples.
Tests can also be hidden with the `@HiddenTest` attribute. This means
that particular test doesn't get run by default but can still be run
by passing its name as a command-line argument. `HiddenTest` takes
a compile-time string to list the reason why the test is hidden. This
would usually be a bug id but can be anything the user wants.

Similarly, `@ShouldFail` is used to decorate a test that is
expected to fail, an also requires a compile-time string.
`@ShouldFail` should be preferred to `@HiddenTest`. If the
relevant bug is fixed or not-yet-implemented functionality is done,
the test will then fail, which makes them harder to sweep
under the carpet and forget about.

It is possible to instantiate a function test case multiple times,
once per value to be passed in. To do so, simply declare a test
function that takes on parameter and add UDAs of that type to
the test function. The `testValues` function in the
[attributes test](tests/pass/attributes.d).

Since D packages are just directories and there the compiler can't
read the filesystem at compile-time, there is no way to automatically
add all tests in a package.  To mitigate this and avoid having to
manually write the name of all the modules containing tests, a utility
called [`dtest`](https://github.com/atilaneves/dtest) can be used to
generate a source file automatically. Simply pass in the desired
directories to scan as command-line arguments. It automatically
generates a file, executes it with rdmd, and prints the result.
Use the -h option to get help on the command. To try it out,
run `dtest -usource -t tests/pass` to run the passing tests,
`dtest -usource -t tests/fail` to run the failing tests,
or simply `dtest` to run all of them. You can also run
either example file with `rdmd -Isource example/<filename>`.

There is support for debug prints in the tests with the `-d` switch.
This is only supported in single-threaded mode (`-s`). Setting `-d`
without `-s` will trigger a warning followed by the forceful use of
`-s`.  TestCases and test functions can print debug output with the
function `writelnUt` available [here](source/unit_threaded/io.d).

Tests can be run in random order. To do so, use the `-r` option.
A seed will be printed so that the same run can be repeated by
using the `--seed` option. This implies running in a single thread.

Since code under test might not be thread-safe, the `@Serial`
attribute can be used on a test. This causes all tests in the same
module that have this attribute to be executed sequentially so they
don't interleave with one another.

Related Projects
----------------
- [dunit](https://github.com/linkrope/dunit):
  xUnit Testing Framework for D
- [DMocks-revived](https://github.com/QAston/DMocks-revived):
  a mock-object framework that allows to mock interfaces or classes
- [deject](https://github.com/bgertzfield/deject): automatic dependency injection
- [specd](https://github.com/jostly/specd):
  a unit testing framework inspired by [specs2](http://etorreborre.github.io/specs2/) and [ScalaTest](http://www.scalatest.org)
- [DUnit](https://github.com/kalekold/dunit):
  a toolkit of test assertions and a template mixin to enable mocking
