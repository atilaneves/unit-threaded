import unit_threaded.light: check;

void main() @system
{
    check!((int a) @system {
        /* ... can do unsafe stuff here ... */
        return true;
    });
}
