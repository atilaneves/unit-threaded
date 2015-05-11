module tests.fail.klass;

import unit_threaded;

interface IService { }
class Service: IService { }

void testCastNotAllowed() {
   IService x = new Service();
   IService y = new Service();
   checkEqual(x, y);
}
