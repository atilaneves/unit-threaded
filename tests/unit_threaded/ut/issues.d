module unit_threaded.ut.issues;

import unit_threaded;


interface ICalcView {
   @property string total() @safe pure;
   @property void total(string t) @safe pure;
}

class CalcController {
    private ICalcView view;

    this(ICalcView view) @safe pure {
        this.view = view;
    }

    void onClick(int number) @safe pure {
        import std.conv: to;
        view.total = number.to!string;
    }
}


@("54")
@safe pure unittest {
   auto m = mock!ICalcView;
   m.expect!"total"("42");

   auto ctrl = new CalcController(m);
   ctrl.onClick(42);

   m.verify;
}


@("82")
@safe unittest {

    import std.exception: assertThrown;

    static class A {
        string x;

        override string toString() const {
            return x;
        }
    }

    class B : A {}

    auto actual = new B;
    auto expected = new B;

    actual.x = "foo";
    expected.x = "bar";

    assertThrown(actual.shouldEqual(expected));
}


@("124")
@safe pure unittest {
    static struct Array {

        alias opSlice this;

        private int[] ints;

        bool opCast(T)() const if(is(T == bool)) {
            return ints.length != 0;
        }

        inout(int)[] opSlice() inout {
            return ints;
        }
    }

    {
        auto arr = Array([1, 2, 3]);
        arr.shouldEqual([1, 2, 3]);
    }

    {
        const arr = Array([1, 2, 3]);
        arr.shouldEqual([1, 2, 3]);
    }

}
