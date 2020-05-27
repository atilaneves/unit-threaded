import unit_threaded;

bool func (uint) @safe { return true; }

@("Safety test")
@safe unittest
{
    check!func;
}


void main() {

}
