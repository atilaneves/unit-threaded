import unit_threaded;

@("private or protected members") @safe pure unittest {
    interface InterfaceWithProtected {
        bool result();
        protected final void inner(int i) { }
    }

    auto m = mock!InterfaceWithProtected;
}


struct Struct { }

@("default params")
@safe pure unittest {
    interface Interface {
        void write(Struct stream, ulong nbytes = 0LU);
    }

    auto m = mock!Interface;
}
