module oops;


import unit_threaded;
import std.exception: assertThrown, assertNotThrown;

class CustomException : Exception {
    this(string msg = "") {
            super(msg);
        }
}

class ChildException : CustomException {
    this(string msg = "") {
            super(msg);
        }
}


@("shouldThrow works with non-throwing expression")
unittest {
    assertThrown((2 + 2).shouldThrow);
}


@("shouldThrow works with throwing expression")
unittest {
    void funcThrows() {
        throw new Exception("oops");
    }
    assertNotThrown(funcThrows.shouldThrow);
}

@("shouldThrowExactly works with non -throwing expression")
unittest {
    assertThrown((2 + 2).shouldThrowExactly!ChildException);
}


@("shouldThrowWithMessage works with non-throwing expression")
unittest {
    assertThrown((2 + 2).shouldThrowWithMessage("oops"));
}


@("shouldThrowWithMessage works with throwing expression")
unittest {
    void funcThrows() {
        throw new Exception("oops");
    }
    assertNotThrown(funcThrows.shouldThrowWithMessage("oops"));
    assertThrown(funcThrows.shouldThrowWithMessage("foobar"));
}

@("shouldThrowExactly works with throwing expression")
unittest {

    void throwCustom() {
        throw new CustomException("custom");
    }

    assertNotThrown(throwCustom.shouldThrow);
    assertNotThrown(throwCustom.shouldThrow!CustomException);
    assertNotThrown(throwCustom.shouldThrowExactly!CustomException);


    void throwChild() {
        throw new ChildException("child");
    }

    assertNotThrown(throwChild.shouldThrow);
    assertNotThrown(throwChild.shouldThrow!CustomException);
    assertNotThrown(throwChild.shouldThrow!ChildException);

    assertThrown(throwChild.shouldThrowExactly!Exception);
    assertThrown(throwChild.shouldThrowExactly!CustomException);
}
