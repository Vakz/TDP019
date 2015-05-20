require 'test/unit'
require_relative '../shlParse'

# Base class for shl TestCases
class SHLTester < Test::Unit::TestCase

  def initialize f, test_src = ""
    super(f)
    @test_src = Dir.pwd + '/' + test_src
    @parser = SHLParse.new
    @parser.log(false)
  end

  def parse(program)
    @parser.parse(program).evaluate
  end

  def load_and_run(file)
    src = File.read @test_src + '/' + file
    parse(src)
  end
end
