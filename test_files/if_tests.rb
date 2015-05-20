#!/usr/bin/ruby
require_relative './shl_tester'

class IfTests < SHLTester

  def initialize f
    super(f, "if_test_files")
  end

  def test_simple_ifs
    assert_equal(5, load_and_run('i_t.shl'))
    assert_equal(0, load_and_run('i_t_e.shl'))
    assert_equal(1, load_and_run('i_f_e.shl'))
    assert_equal(0, load_and_run('i_t_ei_f.shl'))
    assert_equal(1, load_and_run('i_f_ei_t.shl'))
    assert_equal(0, load_and_run('i_t_ei_f_e.shl'))
    assert_equal(1, load_and_run('i_f_ei_t_e.shl'))
    assert_equal(2, load_and_run('i_f_ei_f_e.shl'))
    assert_equal(2, load_and_run('i_f_ei_f_ei_t.shl'))
  end

  def test_nested_ifs
    assert_equal(0, load_and_run('i_t_i_t.shl'))
    assert_equal(1, load_and_run('i_t_i_f_e.shl'))
  end
end
