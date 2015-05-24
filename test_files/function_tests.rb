#!/usr/bin/ruby
require_relative './shl_tester'

class FunctionTests < SHLTester

  def test_simple
    assert_equal(2, parse('@f{ <- 2; } <- f();'))
    assert_equal(2, parse('@f(){ <- 2;} <- f();'))
    assert_equal(2, parse('@f(a){ <- a; } <- f(2);'))
    assert_equal(2, parse('@f(){a = 2; <- a;} <- f();'))
  end

  def test_constant_builtin_calls
    assert_equal('aaa', parse('<- "a".times(3);'))
    assert(parse('<- ["a"].includes("a");'))
    assert_equal([1, 2], parse('<- [1].append(2);'))
    assert(parse('<- {2: 4}.has_key(2);'))
    assert(parse('<- 2.is_even();'))
  end

  def test_variable_builtin_calls
    assert_equal('aaa', parse('a = "a"; <- a.times(3);'))
    assert(parse('<- a = ["a"]; <- a.includes("a");'))
    assert_equal([1, 2], parse('a = [1]; a.append(2); <- a;'))
    assert(parse('<- a = {2: 4}; <- a.has_key(2);'))
    assert(parse('<- a = 2; a.is_even();'))
  end

  def test_nested
    assert_equal(2, parse('@f{ @b(){ <- 2;} <- b(); } <- f();'))
  end

  def test_parallell
    assert_equal(2, parse('@f{ <- 2;} @b{ <- f(); } <- b();'))
  end

  def test_bracket_calls
    assert_equal(2, parse('a = [2]; <- a[0];'))
    assert_equal(2, parse('a = [1,2]; <- a[1];'))
    assert_equal(2, parse('a = []; a[0] = 2; <- a[0];'))
    assert_equal(2, parse('a = {1: 2}; <- a[1];'))
    assert_equal(2, parse('a = {}; a[1] = 2; <- a[1];'))
  end

end
