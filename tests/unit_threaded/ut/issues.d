module unit_threaded.ut.issues;

import unit_threaded;


interface ICalcView {
   @property string total() @safe;
   @property void total(string t) @safe;
}

class CalcController {
    private ICalcView view;

    this(ICalcView view) @safe {
        this.view = view;
    }

    void onClick(int number) @safe {
        import std.conv: to;
        view.total = number.to!string;
    }
}


@("54")
@safe unittest {
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
