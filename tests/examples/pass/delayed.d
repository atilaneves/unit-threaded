module tests.pass.delayed;

import unit_threaded;
import core.thread;


//the tests below should take only 50ms in total if using parallelism
//(given enough cores)
unittest {
    Thread.sleep(50.msecs);
}

unittest {
    Thread.sleep(50.msecs);
}

unittest {
    Thread.sleep(50.msecs);
}

unittest {
    Thread.sleep(50.msecs);
}
