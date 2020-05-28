module tests.fail.delayed;

import unit_threaded;
import core.thread;


//the tests below should take only 1 second in total if using parallelism
//(given enough cores)
unittest {
    Thread.sleep(1.seconds);
}

unittest {
    Thread.sleep(1.seconds);
}

unittest {
    Thread.sleep(1.seconds);
}

unittest {
    Thread.sleep(1.seconds);
}
