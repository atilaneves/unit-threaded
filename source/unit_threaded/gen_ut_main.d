/**
Uses the $(D genUtMain) mixin to implement a runnable program.
This module may be run by rdmd.

Please consult the documentation in gen_ut_main_mixin.
*/
module std.experimental.gen_ut_main;

import unit_threaded.runtime;

mixin genUtMain;
