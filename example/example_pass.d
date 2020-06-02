import unit_threaded;

//these must all be imported in order to be used as a symbol
import tests.pass.normal;
import tests.pass.delayed;
import tests.pass.attributes;
import tests.pass.io;
import tests.pass.mock;

int main(string[] args) {
    return args.runTests!(
        tests.pass.normal,
        tests.pass.delayed,
        tests.pass.attributes,
        tests.pass.io,
        tests.pass.property,
        tests.pass.mock,
    );
}
