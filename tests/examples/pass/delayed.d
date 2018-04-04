module tests.pass.delayed;

import unit_threaded;
import core.thread;


//the tests below should take only 1 second in total if using parallelism
//(given enough cores)
void testLongRunning1() {
    Thread.sleep(1.seconds);
}

void testLongRunning2() {
    Thread.sleep(1.seconds);
}

void testLongRunning3() {
    Thread.sleep(1.seconds);
}

void testLongRunning4() {
    Thread.sleep(1.seconds);
}
