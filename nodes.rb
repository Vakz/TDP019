class Scope
  def initialize( upper_scope = nil )
    @upper = upper_scope
    @vars = {}
    @funcs = {}
  end

  #recursively get variables through upper scopes if not found
  def get_var( var )
    if vars.has_key?( var )
      result = vars[var]
    elsif upper_scope != nil
      result = upper_scope.get_var( var )
    else
      result = nil

    result
  end

  def set_var( name, value )
    @vars[name] = value
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
