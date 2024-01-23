module unit_threaded.ut.runner_options;

import unit_threaded.runner.options: Options;

@("basic cmdline parsing")
unittest {
    const options = Options(["ut", "-j2", "-d", "-e", "-l", "--seed", "123", "-t", "-c", "-q", "mytest1", "mytest2"]);

    version(unitUnthreaded)
        assert(options.numThreads == 1);
    else
        assert(options.numThreads == 2);
    assert(options.testsToRun == ["mytest1", "mytest2"]);
    assert(options.debugOutput);
    assert(options.forceEscCodes);
    assert(options.list);
    assert(options.seed == 123);
    assert(options.stackTraces);
    assert(options.showChrono);
    assert(options.quiet);
}

@("-s overrides -j")
unittest {
    const options = Options(["ut", "-s", "-j4"]);
    assert(options.numThreads == 1);
}

@("-r implies -s")
unittest {
    const options = Options(["ut", "-r", "-j4"]);
    assert(options.numThreads == 1);
    assert(options.random);
}
