class Scope
  def initialize( upper_scope = nil )
    @upper = upper_scope
    @vars = {}
    @funcs = {}
  end

  def set_var( name, value )
    @vars[name] = value
  end

  #recursively get variables through upper scopes if not found
  def get_var( name )
    if vars.has_key?( name )
      result = vars[name]
    elsif upper_scope != nil
      result = @upper.get_var( name )
    else
      result = nil

    result
  end

  def add_func( name, node )
    @funcs[name] = node
  end

  def get_func( name )
    if funcs.has_key?( name )
      result = funcs[name]
    elsif upper_scope != nil
      result = @upper.get_func( name )
    else
      result = nil

    result
  end
end

# Top level node, containing all other nodes.
class SHLProgramNode
  def initialize( statements )
    @statements = statements
  end

  def evaluate
    scope = Scope.new
    @statements.each { |s| s.evaluate( scope ) }
  end
end

# Node for function definitions stored in a scope.
class FunctionDefNode
  def initialize( name, vars, block )
    @name, @vars, @block = name, vars, block
  end

  def evaluate( scope )
    new_scope = Scope.new( scope )
    @vars.each { |k,v| new_scope.set_var( k, v ) }
    block.evaluate( new_scope )
  end

# Node for function calls.
class FunctionCall
  def initialize( name )
    @name = name
  end

  def evaluate( scope )
    func = scope.get_func( @name )
    if func != nil
      func.evaluate( scope )
    else
      #Error?
    end
  end
end

# Node for a block of code within brackets.
class BlockNode < SHLProgramNode
  def evaluate( scope )
    new_scope = Scope.new( scope )
    @statements.each { |s| s.evaluate( new_scope ) }
  end
end

class IfNode
  def initialize( i_cond, i_block, ei_conds = nil, ei_blocks = nil, e_block = nil )
    @i_cond, @i_block = i_cond, i_block
    @ei_conds, @ei_blocks, @e_block = ei_conds, ei_blocks, e_block
  end

  def evaluate( scope )
    if i_cond.evaluate( scope )
      i_block.evaluate( scope )
      return
    end

    if ei_conds != nil
      ei_conds.each_with_index do |c,i|
        if c.evaluate( scope )
          ei_blocks[i].evaluate( scope )
          return
        end
      end
    end

    if e_block != nil
      e_block.evaluate( scope )
      return
    end

    return
  end
end

# Node for comparisons.
class ComparisonNode
  def initialize( lhs, rhs, op )
    @lhs, @rhs, @op = lhs, rhs, op
  end

  def evaluate( scope )
    @lhs.evaluate( scope ).send( @op, @rhs.evaluate( scope ) )
  end
end

# Node for assignment, stores a name and a value (node).
class AssignmentNode
  def initialize( name, value )
    @name, @value = name, value
  end

  def evaluate( scope )
    if @value.is_a?( ConstantNode )
      scope.set_var( @name, @value.evaluate )
    else
      scope.set_var( @name, @value.evaluate( scope ) )
    end
  end
end

# Node for getting the value from a variable.
class VariableNode
  def initialize( name )
    @name = name
  end

  def evaluate( scope )
    value = scope.get_var( @name )
    if value != nil
      return value
    else
      #Error?
    end
  end
end

# Representing a constant, such as the literal 2.
class ConstantNode
  def initialize( value )
    @value = value
  end

  def evaluate
    @value
  end
end
