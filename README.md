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

1. To run in parallel by default
2. Support for built-in `unittest` blocks - no need to reinvent the wheel
3. To be able to run specific tests or group of tests via
the command-line
4. No test registration. Tests are discovered with D's compile-time
reflection
5. Suppress tested code stdio and stderr output by default (important
when running in multiple threads).
6. Have a special mode that only works when using a single thread
under which tested code output is turned back on, as well as special
writelnUt debug messages.
7. Ability to temporarily hide tests from being run by default whilst
stil being able to run them

Quick start with dub
----------------------

dub runs tests with `dub test`. Unfortunately, due to the nature of
D's compile-time reflection, to use this library a test runner file
listing all modules to reflect on must exist. Since this is a tedious
task and easily automated, unit-threaded has a dub configuration
called `gen_ut_main` to do just that.  To use unit-threaded with a dub
project, you can use a `unittest` configuration as exemplified in this
`dub.json`:

    {
        "name": "myproject",
        "targetType": "executable",
        "targetPath": "bin",
        "configurations": [
            { "name": "executable" },
            {
                "name": "unittest",
                "preBuildCommands": ["dub run unit-threaded -c gen_ut_main -- -f bin/ut.d"],
                "mainSourceFile": "bin/ut.d",
                "excludedSourceFiles": "src/main.d",
                "dependencies": {
                    "unit-threaded": "~>0.6.0"
                }
            }
        ]
    }

`excludedSourceFiles` is there to not compile the file containing the
`main` function to avoid linker errors. As an alternative to using
`excludedSourceFiles`, the "real" `main` can be versioned out:

    version(unittest) {}
    else {
        void main() {
            //...
        }
    }

Your unittest blocks will now be run in threads and can be run individually.
To name each unittest, simply attach a string UDA to it:

    @("Test that 2 + 3 is 5")
    unittest {
        assert(2 + 3 == 5);
    }


You can also have multiple configurations for running unit tests, e.g. one that uses
the standard D runtime unittest runner and one that uses unit-threaded:

    "configurations": [
        {"name": "ut_default"},
        {
          "name": "unittest",
          "preBuildCommands: ["dub run unit-threaded -c gen_ut_main -- -f bin/ut.d"],
          "mainSourceFile": "bin/ut.d",
          ...
        }
    ]

In this example, `dub test -c ut_default` runs as usual if you don't use this
library, and `dub test` runs with the unit-threaded test runner.

To use unit-threaded's assertions or UDA-based features, you must import the library:

    version(unittest) { import unit_threaded; }
    else              { enum ShouldFail; } // so production builds compile

    int adder(int i, int j) { return i + j; }

    @("Test adder") unittest {
        adder(2 + 3).shouldEqual(5);
    }

    @("Test adder fails", ShouldFail) unittest {
        adder(2 + 3).shouldEqual(7);
    }

If using a custom dub configuration for unit-threaded as shown above, a version
block can be used on `Have_unit_threaded` (this is added by dub to the build).


Advanced Usage
-------------

There are two example programs in the [`example`](example/) folder,
one with passing unit tests and the other failing, to show what the
output looks like in each case. Because of the way D packages work,
they must be run from the top-level directory of the repository.

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

There is no need to register tests. The registration is implicit
and happens with:

* D's `unittest`` blocks
* Classes that derive from `TestCase` and override `test()`
* Functions with a camelCase name beginning with `test` (e.g. `testFoo()`)

The modules to be reflected on must be specified when calling
`runTests`, but that's usually done as shown in the dub configuration
above. Private functions are skipped. `TestCase` also has support for
`setup()` and `shutdown()`, child classes need only override the
appropriate functions(s).

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
[attributes test](tests/pass/attributes.d) is an example of this.

Since D packages are just directories and there the compiler can't
read the filesystem at compile-time, there is no way to automatically
add all tests in a package.  To mitigate this and avoid having to
manually write the name of all the modules containing tests,
a dub configuration called `gen_ut_main` runs unit-threaded as
a command-line utility to write the file for you.

There is support for debug prints in the tests with the `-d` switch.
This is only supported in single-threaded mode (`-s`). Setting `-d`
without `-s` will trigger a warning followed by the forceful use of
`-s`.  TestCases and test functions can print debug output with the
function `writelnUt` available [here](source/unit_threaded/io.d).

Tests can be run in random order instead of in threads.  To do so, use
the `-r` option.  A seed will be printed so that the same run can be
repeated by using the `--seed` option. This implies running in a
single thread.

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
