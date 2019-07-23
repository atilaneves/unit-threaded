unittest {
    import unit_threaded: shouldThrowWithMessage;
    import nogc: NoGcException;
    fun.shouldThrowWithMessage!NoGcException("why hello there");
}


void fun() {
    import nogc: enforce;
    enforce(false, "why hello there");
}

void main() {}
