#!/usr/bin/ruby
require_relative './shl_tester'

class MathTests < SHLTester
  def test_simple
    assert_equal(-1, parse('<- -1;'))
    assert_equal(2, parse('<- 1+1;'))
    assert_equal(4, parse('<- 2*2;'))
    assert_equal(0, parse('<- 2-2;'))
    assert_equal(9, parse('<- 3**2;'))
    assert_equal(3, parse('<- 12 / 4;'))
    assert_equal(3.5, parse('<- 14 / 4;'))
    assert_equal(3, parse('<- 12 // 4;'))
    assert_equal(3, parse('<- 13 // 4;'))
  end

  def test_compound
    assert_equal(1, parse('<- 1+1-1;'))
    assert_equal(3, parse('<- 1+1+1;'))
    assert_equal(-1, parse('<- 1-1-1;'))
    assert_equal(-3, parse('<- -1-1-1;'))
    assert_equal(-4, parse('<- 2* -2;'))
    assert_equal(5, parse('<- 1 + 2 * 2;'))
    assert_equal(5, parse('<- 2 * 2 + 1;'))
    assert_equal(4, parse('<- 2 * (1+1);'))
    assert_equal(4, parse('<- (1+1)*2;'))
    assert_equal(10, parse('<- 3**2 + 1;'))
    assert_equal(10, parse('<- 1 + 3**2;'))
    assert_equal(5, parse('<- 8 // 2 + 1;'))
    assert_equal(5, parse('<- 9 // 2 + 1;'))
    assert_equal(5.5, parse('<- 9 / 2 + 1;'))
  end


end
