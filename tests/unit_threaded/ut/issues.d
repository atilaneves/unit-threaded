module unit_threaded.ut.issues;

import unit_threaded;


interface ICalcView {
   @property string total();
   @property void total(string t);
}

class CalcController {
    private ICalcView view;
    this(ICalcView view) { this.view = view; }

    void onClick(int number) {
        import std.conv: to;
        view.total = number.to!string;
    }
}


@("54")
unittest {
   auto m = mock!ICalcView;
   m.expect!"total"("42");

   auto ctrl = new CalcController(m);
   ctrl.onClick(42);

   m.verify;
}


@("82")
unittest {

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
