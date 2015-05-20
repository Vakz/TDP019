#!/usr/bin/ruby
require 'test/unit'
require_relative './shl_tester'

# Class for unit tests
class ConstantTests < SHLTester

  def return_tests(vars)
    program = '<- %s;'
    vars.each do |x|
      assert_equal(x, parse(program % x))
    end
  end

  def test_integers
    return_tests([0, -0, 1, -1, 10, -10])
  end

  def test_floats
    return_tests([0.0, -0.0, 0.1, -0.1, 1.0, -1.0, 1.1, -1.1, 11.1, -11.1, 1.11,
                  -1.11, 11.11, -11.11])
  end

  def test_bools
    return_tests([true, false])
  end

  def test_strings
    assert_equal('', parse('<- "";'))
    assert_equal('a', parse('<- "a";'))
    assert_equal('åäö', parse('<- "åäö";'))
    assert_equal('123', parse('<- "123";'))
  end

  def test_nil
    assert_nil(parse('<- nil;'))
  end

  def test_const_array
    assert_equal([], parse('<- [];'))
    assert_equal([1], parse('<- [1];'))
    assert_equal([1, 2], parse('<- [1,2];'))
    assert_equal([''], parse('<- [""];'))
    assert_equal(['asd'], parse('<- ["asd"];'))
  end

  def test_const_hash
    assert_equal({}, parse('<- {};'))
    assert_equal({ 1 => 2 }, parse('<- {1: 2};'))
    assert_equal({ 'a' => 1 }, parse('<- {"a": 1};'))
    assert_equal({ 1 => 'a' }, parse('<- {1: "a"};'))
    assert_equal({ true => nil }, parse('<- {true: nil};'))
  end
end
