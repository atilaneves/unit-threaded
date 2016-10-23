unit-threaded
=============
[![Build Status](https://travis-ci.org/atilaneves/unit-threaded.png?branch=master)](https://travis-ci.org/atilaneves/unit-threaded)

[My DConf2016 Lightning talk demonstrating unit-threaded](https://www.youtube.com/watch?v=yIH_0ew-maI#t=6m50s).

Multi-threaded advanced unit test framework for [the D programming language](https://dlang.org/).

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
`writelnUt` debug messages.
7. Ability to temporarily hide tests from being run by default whilst
still being able to run them

Quick start with dub
----------------------

dub runs tests with `dub test`. Unfortunately, due to the nature of
D's compile-time reflection, to use this library a test runner file
listing all modules to reflect on must exist. Since this is a tedious
task and easily automated, unit-threaded has a dub configuration
called `gen_ut_main` to do just that.  To use unit-threaded with a dub
project, you can use a `unittest` configuration as exemplified in this
`dub.json`:

```json
{
    "name": "myproject",
    "targetType": "executable",
    "targetPath": "bin",
    "configurations": [
        { "name": "executable" },
        {
            "name": "unittest",
            "targetType": "executable",
            "preBuildCommands": ["dub run unit-threaded -c gen_ut_main -- -f bin/ut.d"],
            "mainSourceFile": "bin/ut.d",
            "excludedSourceFiles": ["src/main.d"],
            "dependencies": {
                "unit-threaded": "~>0.6.0"
            }
        }
    ]
}
```

`excludedSourceFiles` is there to not compile the file containing the
`main` function to avoid linker errors. As an alternative to using
`excludedSourceFiles`, the "real" `main` can be versioned out:

```d
version(unittest) {}
else {
    void main() {
        //...
    }
}
```

Your unittest blocks will now be run in threads and can be run individually.
To name each unittest, simply attach a string UDA to it:

```d
@("Test that 2 + 3 is 5")
unittest {
    assert(2 + 3 == 5);
}
```

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

```d
version(unittest) { import unit_threaded; }
else              { enum ShouldFail; } // so production builds compile

int adder(int i, int j) { return i + j; }

@("Test adder") unittest {
    adder(2, 3).shouldEqual(5);
}

@("Test adder fails", ShouldFail) unittest {
    adder(2, 3).shouldEqual(7);
}
```

If using a custom dub configuration for unit-threaded as shown above, a version
block can be used on `Have_unit_threaded` (this is added by dub to the build).

Advanced Usage: Attributes
--------------------------

`@ShouldFail` is used to decorate a test that is
expected to fail, and can be passed a string to explain why.
`@ShouldFail` should be preferred to `@HiddenTest`. If the
relevant bug is fixed or not-yet-implemented functionality is done,
the test will then fail, which makes them harder to sweep
under the carpet and forget about.

Since code under test might not be thread-safe, the `@Serial`
attribute can be used on a test. This causes all tests in the same
module that have this attribute to be executed sequentially so they
don't interleave with one another.

The `@UnitTest` and `@DontTest` attributes are explained below.

There is support for parameterized tests. This means running the test
code multiple times, either with different values or different types.
At the moment this feature cannot be used with the built-in unittest
blocks.

For values and built-in unit tests, use the `@Values` UDA to supply
test values and `getValue` with the appropriate type to retrive them:

```d
@Values(2, 4, 6)
unittest {
    assert(getValue!int % 0 == 2);
}
```

This will run the test 3 times, and the reporting
will consider it to be 3 separate tests.


If more than one `@Values` UDA is used, then the test gets instantiated
with the cartesian product of values, e.g.

```d
@Values(1, 2)
@Values("foo", "bar")
unittest {
    getValue!(int, 0); // gets the integer value (1 or 2)
    getValue!(string, 1); // gets the string value ("foo" or "bar")
}
```

The test above is instantiated 4 times for each one of the possible
combinations. This helps to reduce boilerplate and repeated tests.

You can also declare a test function that takes parameters of the
appropriate types and add UDAs with the values desired, e.g.

```d
@(2, 4, 6)
void testEven(int i) {
    (i % 0 == 2).shouldBeTrue;
}
```

For a cartesian product, simply declare more parameters and add
UDAs as appropriate.

For types, use the `@Types` UDA on a template function with exactly
one compile-time parameter:

```d
@Types!(int, byte)
void testInit(T)() {
    T.init.shouldEqual(0);
}
```

The `@Name` UDA can be used instead of a plain string in order to name
a `unittest` block.

unit-threaded uses D's package and module system to make it possible
to select a subset of tests to run. Sometimes however, tests in
different modules address cross-cutting concerns and it may be
desirable to indicate this grouping in order to select only those
tests. The `@Tags` UDA can be used to do that. Any number of tags
can be applied to a test:

```d
@Tags("foo", "tagged")
unittest { ... }
```

The strings a test is tagged with can be used by the test runner
binary to constrain which tests to run either by selecting tests
with or without tags:

    ./ut @foo ~@bar

That will run all tests that have the "foo" tag that also don't have
the "bar" tag.

If using value or type parameterized tests, the `@AutoTags` UDA will
give each sub-test a tag corresponding to their parameter:

```d
@Values("foo", "bar")
@AutoTags // equivalent to writing @Tags("foo", "bar")
@("autotag_test")
unittest {
   // ...
}
```

The `@Setup` and `@Shutdown` UDAs can be attached to a
free function in a module. If they are, they will be run before/after
each `unittest` block in a composite (usually a module). This feature
currently only works for `unittest` blocks, not free functions.
Classes could override `setup` and `shutdown` already.

Property-based testing
----------------------

There is preliminary and experimental support for property-based testing.
The current types supported are all primitive types, all 3 string types,
and arrays of these types. To check a property use the `check` function
from `unit_threaded.property` with a function returning `bool`:

```d
check!((int a) => a % 2 == 0);
```

The above example will obviously fail. By default `check` runs the property
function with 100 random values, pass it a different runtime parameter
to change that:

```d
check!((int a) => a % 2 == 0)(10_000); // will still fail
```

If using compile-time delegates as above, the types of the input parameters
must be explicitly stated. Multiple parameters can be used as long as
each one is of one of the currently supported types.

Mocking
--------

Classes and interfaces can be mocked like so:


```d
interface Foo { int foo(int, string); }
int fun(Foo f, int i, string s) { return f.foo(i * 2, s ~ "stuff"); }

auto m = mock!Foo;
m.expect!"foo";
fun(m, 3, "bar");
m.verify; // throws if not called
```

To check the values passed in, pass them to `expect`:


```d
m.expect!"foo"(6, "barstuff");
fun(m , 3, "bar");
m.verify;
```

Either call `expect` then `verify` or call `expectCalled` at the end:

```d
fun(m, 3, "bar");
m.expectCalled!"foo"(6, "barstuff");
```

The return value is `T.init` unless `returnValue` is called (it's variadic):

```d
m.returnValue!"foo"(2, 3, 4);
assert(fun(m, 3, "bar") == 2);
assert(fun(m, 3, "bar") == 3);
assert(fun(m, 3, "bar") == 4);
assert(fun(m, 3, "bar") == 0);
```

Structs can also be mocked:

```d
int fun(T)(T f, int i, string s) { return f.foo(i * 2, s ~ "stuff"); }
auto m = mockStruct(2, 3, 4); // the ints are return values
assert(fun(m, 3, "bar") == 2);
m.expectCalled!"foo"(6, "barstuff");
```

Command-line Parameters
-----------------------

There is support for debug prints in the tests with the `-d` switch.
This is only supported in single-threaded mode (`-s`). Setting `-d`
without `-s` will trigger a warning followed by the forceful use of
`-s`.  TestCases and test functions can print debug output with the
function `writelnUt` available [here](source/unit_threaded/io.d).

Tests can be run in random order instead of in threads.  To do so, use
the `-r` option.  A seed will be printed so that the same run can be
repeated by using the `--seed` option. This implies running in a
single thread.


Integration tests and a sandbox environment
------------------------------------------

If you want to write tests that read from and write to the file system,
you can use the `Sandbox` struct from
[`unit_threaded.integration`](source/unit_threaded/integration) like so:

```d
with(immutable Sandbox()) {
    writeFile("foo.txt", "foobarbaz\ntoto"); // can also pass string[] for lines
    shouldExist("foo.txt");
    shouldNotExist("bar.txt");
    shouldEqualLines("foo.txt", ["foobarbaz", "toto"]);
}
```

By default the sandbox main path is `tmp/unit-threaded` but you can change
that by calling `Sandbox.setPath`


Test Registration and Test Runner
---------------------------------

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
* Functions with a camelCase name beginning with `test` (e.g. `testFoo()`)
* Classes that derive from `TestCase` and override `test()`

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

Since D packages are just directories and there the compiler can't
read the filesystem at compile-time, there is no way to automatically
add all tests in a package.  To mitigate this and avoid having to
manually write the name of all the modules containing tests,
a dub configuration called `gen_ut_main` runs unit-threaded as
a command-line utility to write the file for you.



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
