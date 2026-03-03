This module contains the following assertions:

- shouldBeTrue
- shouldBeFalse
- shouldEqual
- shouldNotEqual
- shouldBeNull
- shouldNotBeNull
- shouldBeIn
- shouldNotBeIn
- shouldThrow
- shouldThrowExactly
- shouldNotThrow
- shouldThrowWithMessage
- shouldApproxEqual
- shouldBeEmpty
- shouldNotBeEmpty
- shouldBeGreaterThan
- shouldBeSmallerThan
- shouldBeSameSetAs
- shouldNotBeSameSetAs
- shouldBeSameJsonAs
- shouldBeBetween
- shouldApprox

It also contains the `should` -testing DSL. I.e.:
```
1.should == 1;
1.should.not == 2;
1.should in [1, 2, 3];
4.should.not in [1, 2, 3];
```
