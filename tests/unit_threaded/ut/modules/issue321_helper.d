module unit_threaded.ut.modules.issue321_helper;

import unit_threaded.ut.modules.issue321;

struct Bar {
    alias Bell = Foo;
}

alias Other = Foo;
