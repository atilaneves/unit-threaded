module tests.pass.issue51;

import tests.pass.types;
import unit_threaded;

@safe pure unittest {
    interface Foo {
        A foo() @safe pure;
    }

    A fun(Foo f) {
        return f.foo();
    }

    enum isString(alias T) = is(typeof(T) == string);
    static assert(isString!"tests.pass.types");
    auto m = mock!(Foo);
    m.expect!"foo";
    fun(m);
}
