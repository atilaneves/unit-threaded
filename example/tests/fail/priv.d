module example.tests.fail.priv;

import unit_threaded.all;


/**
 * Private stuff to test compile-time scanning doesn't break
 */
private void randomPrivateFunction() {
}

private class MyPrivateClass {
private:
    int i;
}

class ClassWithPrivateData {
private:
    int i;
    double d;
    string s;
    int[] a;
    int[int] aa;
}


struct StructWithPrivateData {
private:
    int i;
    double d;
    string s;
    int[] a;
    int[int] aa;
}
