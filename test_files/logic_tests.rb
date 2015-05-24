#!/usr/bin/ruby
require_relative './shl_tester'

class LogicTests < SHLTester
  def test_boolean
    assert(parse('<- true;'))
    assert(!parse('<- false;'))
    assert(parse('<- true && true;'))
    assert(parse('<- true || false;'))
    assert(parse('<- false || true;'))
    assert(!parse('<- true && false;'))
    assert(!parse('<- false && true;'))
  end

  def test_comparison
    assert(parse('<- "aa" == "aa";'))
    assert(parse('<- "aa" != "bb";'))

    assert(parse('<- 1 == 1;'))
    assert(!parse('<- 1 != 1;'))
    assert(parse('<- 1 != 2;'))
    assert(parse('<- 1 <= 1;'))
    assert(parse('<- 1 <= 2;'))
    assert(!parse('<- 1 <= 0;'))
    assert(!parse('<- 1 < 1;'))
    assert(parse('<- 1 < 2;'))
    assert(parse('<- 1 >= 1;'))
    assert(!parse('<- 1 >= 2;'))
    assert(parse('<- 1 >= 0;'))
    assert(!parse('<- 1 < 1;'))
    assert(!parse('<- 1 < 0;'))
    assert(parse('<- 1 < 2;'))
    assert(parse('<- 1 > 0;'))
    assert(!parse('<- 1 > 1;'))
    assert(!parse('<- 1 > 2;'))
  end
end
