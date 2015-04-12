/**
Advanced unit-testing.

Copyright: Atila Neves
License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
Authors: Atila Neves

$(D D)'s $(D unittest) blocks are a built-in feature of the language that allows
for easy unit testing with no boilerplate. As a program grows it's usual to need
or want more advanced testing features, which is provided by this package.

The easiest way to run tests with the functionality provided is to have a $(D D)
module implementing a $(D main) function similar to this one:

-----
import unit_threaded;

int main(string[] args) {
     return runTests!("name.of.mymodule",
                      "name.of.other.module")(args);
}
-----

This will (by default) run all $(D unittest) blocks in the modules passed in as
compile-time parameters in multiple threads. Unit tests can be named: to do so
simply use the supplied $(D Name)
<a href="http://dlang.org/attribute.html#uda">UDA</a>. There are other
supplied UDAs Please consult the relevant documentation.
 */

module unit_threaded;

public import unit_threaded.should;
public import unit_threaded.testcase;
public import unit_threaded.io;
public import unit_threaded.reflection;
