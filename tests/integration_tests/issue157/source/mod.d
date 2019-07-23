unittest {
    import unit_threaded;
    fun.shouldThrowWithMessage("why hello there");
}


void fun() {
    import nogc: enforce;
    enforce(false, "why hello there");
}

void main() {}
