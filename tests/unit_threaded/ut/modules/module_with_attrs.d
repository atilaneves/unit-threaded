module unit_threaded.ut.modules.module_with_attrs;

import unit_threaded.attrs;
import std.exception;

@HiddenTest("foo")
@ShouldFail("bar")
@SingleThreaded
void testAttrs() { }

@ShouldFailWith!Exception
void testOtherAttrs() {}


@ShouldFail
@(1, 2, 3)
void testValues(int i) { }

@DontTest
@("DontTestBlock")
unittest {
    assert(0);
}

@ShouldFail
@("will fail")
unittest {
    assert(0);
}

class TestException : Exception { this(string m) { super(m); } }

@ShouldFailWith!TestException
@("ShouldFailWith that fails due to wrong type")
unittest {
    assert(0);
}

@ShouldFailWith!TestException
@("ShouldFailWith that fails due to not failing")
unittest {
}


@ShouldFailWith!TestException
@("ShouldFailWith that passes")
unittest {
    throw new TestException("you won't see this");
}


@Flaky
@("flaky that passes eventually")
unittest {
    static int i = 0;
    if(i++ % 2 == 0) throw new Exception("failed");
}

@Flaky(1)
@("flaky that fails due to not enough retries")
unittest {
    static int i = 0;
    if(i++ % 2 == 0) throw new Exception("failed");
}
