module tests.fail.klass;

import unit_threaded;

interface IService {
    string toString() @safe pure nothrow const;
}

class Service: IService {
    override string toString() @safe pure nothrow const { return ""; }
}

void testCastNotAllowed() {
   IService x = new Service();
   IService y = new Service();
   shouldEqual(x, y);
}
