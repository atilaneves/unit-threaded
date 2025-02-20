module unit_threaded.ut.modules.issue316;


unittest {
    assert(true, "outside");
}

private struct PrivateStruct {
    unittest {
    }
}
