unit-threaded
=============

Unit test framework for D.

TODO:

- More checks/asserts
    - Arrays
    - Associative arrays
    - Strings
    - etc.
- Use lazy expressions to get better failure messages
- Add sub-packages automatically to get the full tree
- Actually be multi-threaded
- Integrate with built-in unittest blocks (catch AssertionError?)
- Random reordering of tests in single-threaded mode
- Think about splitting code to avoid bloat and decrease linking time
