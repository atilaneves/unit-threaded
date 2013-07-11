unit-threaded
=============

Unit test framework for D.

TODO:

- Use lazy expressions to get better failure messages
- Maybe use decorator to mark testable classes so the compiler can check
- Do not include private functions in the testables list
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
