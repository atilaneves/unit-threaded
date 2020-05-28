module tests.pass.io;

import unit_threaded;


unittest {
    writelnUt("Class writelnUt should only print with '-d' option");
}

unittest {
    writelnUt("But this should show up when using -d option");
}
