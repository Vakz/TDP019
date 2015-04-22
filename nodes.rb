# Top level node, containing all other nodes
class SHLProgramNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate
    @statements.each(&:evaluate)
  end
end

# Representing a constant, such as the literal 2.
class ConstantNode
  def initialize(value)
    @value = value
  end

  def evaluate
    @value
  end
end
