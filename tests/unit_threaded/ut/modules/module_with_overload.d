module unit_threaded.ut.modules.module_with_overload;

void foo(int) { }

void foo(float) { }

@("no-op")
unittest
{
}
