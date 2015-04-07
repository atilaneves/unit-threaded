module unit_threaded.should;

import unit_threaded.check;

alias shouldBeTrue = checkTrue;
alias shouldBeFalse = checkFalse;
alias shouldEqual = checkEqual;
alias shouldNotEqual = checkNotEqual;
alias shouldBeNull = checkNull;
alias shouldNotBeNull = checkNotNull;


void shouldInclude(T, U)(in U container, in T value,
                         in string file = __FILE__, in ulong line = __LINE__)
{
    checkIn(value, container, file, line);
}

void shouldNotInclude(T, U)(in U container, in T value,
                            in string file = __FILE__, in ulong line = __LINE__)
{
    checkNotIn(value, container, file, line);
}

unittest
{
    auto ints = [3, 4, 2, 7];
    ints.shouldInclude(3);
    ints.shouldInclude(7);
    ints.shouldNotInclude(9);

    auto aa = [1:2, 3: 6];
    aa.shouldInclude(1);
    aa.shouldInclude(3);
    aa.shouldNotInclude(2);
}


alias shouldThrow = checkThrown;
alias shouldNotThrow = checkNotThrown;

alias shouldBeEmpty = checkEmpty;
alias shouldNotBeEmpty = checkNotEmpty;

alias shouldBeGreaterThan = checkGreaterThan;
alias shouldBeSmallerThan = checkSmallerThan;
