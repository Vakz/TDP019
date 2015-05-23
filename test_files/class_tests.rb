require_relative './shl_tester'

class ClassTests < SHLTester

  def initialize f
    super(f, 'class_test_files')
  end

  def test_defs
    assert_equal(5, parse('!T{ a = 5; } f = T(); <- f.a;'))
    assert_equal(2, load_and_run('nested_def.shl'))
    assert_equal(2, load_and_run('triple_nested_def.shl'))
    assert_equal(2, load_and_run('nested_assign.shl'))
  end


  def test_member_func_def
    assert_equal(2, load_and_run('simple_member_func.shl'))
    assert_equal(2, load_and_run('parallell_func_call.shl'))
    assert_equal(2, load_and_run('function_call_in_def.shl'))
    assert_equal(2, load_and_run('nested_def_call.shl'))
  end

  def test_arguments
    assert_equal(2, load_and_run('simple_arguments.shl'))
    assert_equal(2, load_and_run('variables_as_arguments.shl'))
    assert_equal(4, load_and_run('variable_use_in_def.shl'))
  end
end
