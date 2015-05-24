#!/usr/bin/ruby
require_relative './shl_tester'

class VariableTests < SHLTester

  def initialize f
    super(f, 'variable_test_files')
  end

  def test_constant_assignments
    assert_equal(0, parse('a = 0; <- a;'))
    assert_equal(true, parse('a = true; <- a;'))
    assert_nil(parse('a = nil; <- a;'))
    assert_equal(0.0, parse('a = 0.0; <- a;'))
  end

  def test_compound_assignments
    assert_equal('a', parse('a = "a"; <- a;'))
    assert_equal([], parse('a = []; <- a;'))
    assert_equal({}, parse('a = {}; <- a;'))
    assert_equal([1], parse('a = [1]; <- a;'))
    assert_equal([1], parse('b = 1; a = [b]; <- a;'))
    assert_equal([1, 2], parse('b = 1; a = [b, 2]; <- a;'))
    assert_equal({ 1 => 2 }, parse('a = {1: 2}; <- a;'))
    assert_equal({ 1 => 2 }, parse('b = 1; a = {b: 2}; <- a;'))
    assert_equal({ 1 => 2 }, parse('b = 2; a = {1: b}; <- a;'))
    assert_equal({ 1 => 2 }, parse('b = 1; c = 2; a = {1: c}; <- a;'))
    assert_equal({ 1 => 2, 3 => 4 }, parse('a = {1: 2, 3: 4}; <- a;'))
  end

  def test_scopes
    assert_equal(2, load_and_run('outer_scope.shl'))
    assert_equal(2, load_and_run('outer_and_local_scope.shl'))
  end
end
