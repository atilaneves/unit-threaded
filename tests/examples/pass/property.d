module tests.pass.property;

import unit_threaded;

@("int[] property")
unittest {
    // probably as unlikely to happen as quantum tunneling to the moon
    check!((int[] a) => a != [0, 1, 2, 3, 4]);
}

@("int[] sorting twice yields the same result") unittest {
    import std.algorithm: sort;
    check!((int[] a) {
        sort(a);
        auto b = a.dup;
        sort(b);
        return a == b;
    });
}


struct MyStruct {
    int i;
}

@("Property testing with user defined type")
unittest {
    checkCustom!(
        () {
            return MyStruct(5);
        },
        (MyStruct s) {
            return s.i == 5;
        });
}

@("Property testing with strings")
unittest {
    check!((string s) {
        import std.utf : validate, UTFException;
        try {
            validate(s);
        } catch (UTFException e) {
            return false;
        }
        return true;
    });
}

@("Property testing with wstrings")
unittest {
    check!((wstring s) {
        import std.utf : validate, UTFException;
        try {
            validate(s);
        } catch (UTFException e) {
            return false;
        }
        return true;
    });
}

@("Property testing with dstrings")
unittest {
    check!((dstring s) {
        import std.utf : validate, UTFException;
        try {
            validate(s);
        } catch (UTFException e) {
            return false;
        }
        return true;
    });
}
