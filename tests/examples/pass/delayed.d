module tests.pass.delayed;

import unit_threaded;
import core.thread;


//the tests below should take only 50ms in total if using parallelism
//(given enough cores)
void testLongRunning1() {
    Thread.sleep(50.msecs);
}

void testLongRunning2() {
    Thread.sleep(50.msecs);
}

void testLongRunning3() {
    Thread.sleep(50.msecs);
}

void testLongRunning4() {
    Thread.sleep(50.msecs);
}
