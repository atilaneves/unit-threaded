module example.tests.pass.delayed;

import unit_threaded.all;
import core.thread;


//the tests below should take only 1 second in total if using parallelism
//(given enough cores)
void testLongRunning1() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning2() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning3() {
    Thread.sleep( dur!"seconds"(1));
}

void testLongRunning4() {
    Thread.sleep( dur!"seconds"(1));
}
