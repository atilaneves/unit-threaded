module tests.fail.composite;

import unit_threaded.should;
import unit_threaded.attrs;


@SingleThreaded
unittest {
    true.shouldBeTrue;
    (2 + 3).shouldEqual(5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
    (2 + 3).shouldEqual(5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
    (2 + 3).shouldEqual(5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
    shouldEqual(2 + 3, 5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
    shouldEqual(2 + 3, 5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
    shouldEqual(2 + 3, 5);
}

@SingleThreaded
unittest {
    true.shouldBeTrue;
}

@SingleThreaded
unittest {
    shouldBeTrue(false);
}
