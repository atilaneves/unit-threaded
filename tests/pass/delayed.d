module tests.pass.delayed;

import unit_threaded;
import core.thread;


//the tests below should take only 1 second in total if using parallelism
//(given enough cores)
@name("testLongRunning1") unittest
{
    Thread.sleep(1.seconds);
}

@name("testLongRunning2") unittest
{
    Thread.sleep(1.seconds);
}

@name("testLongRunning3") unittest
{
    Thread.sleep(1.seconds);
}

@name("testLongRunning4") unittest
{
    Thread.sleep(1.seconds);
}
