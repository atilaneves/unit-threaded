module tests.fail.klass;

import unit_threaded;

interface IService {
    string toString() @safe pure nothrow const;
}

class Service: IService {
    override string toString() @safe pure nothrow const { return ""; }
}

@("castNotAllowed")
unittest {
   IService x = new Service();
   IService y = new Service();
   shouldEqual(x, y);
}
