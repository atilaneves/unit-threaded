unit-threaded
=============

Unit test framework for D.

TODO:

- Actually be multi-threaded
- More checks/asserts
    - Arrays
    - Associative arrays
    - Strings
    - etc.
- Integrate with built-in unittest blocks (catch AssertionError?)
- Allow test functions and any class to be testable
- Add sub-packages automatically to get the full tree
- Random reordering of tests in single-threaded mode
- Think about splitting code to avoid bloat and decrease linking time
