require './builtins'

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
    if @vars.has_key?( name )
      result = @vars[name]
    elsif @upper != nil
      result = @upper.get_var( name )
    else
      result = nil
    end
    result
  end

  def add_func( name, node )
    #Check builtins first
    @funcs[name] = node
  end

  def get_func( name )
    if @funcs.has_key?( name )
      result = @funcs[name]
    elsif @upper != nil
      result = @upper.get_func( name )
    else
      result = nil
    end
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

# Node for function definition
class FunctionDefNode
  def initialize( name, vars, block )
    @name, @vars, @block = name, vars, block
  end

  def evaluate( scope )
    scope.add_func( @name, FunctionNode.new( @name, @vars, @block ) )
  end
end

# Function node stored in scope
class FunctionNode
  def initialize( name, vars, block )
    @name, @vars, @block = name, vars, block
  end

  def evaluate( scope, params )
    new_scope = Scope.new( scope )

    #deep copy of vars to preserve values.
    vars_copy = Array.new
    @vars.each { |e| vars_copy.push(e.dup) }

    #add param values to vars
    params.each_with_index { |p,i| vars_copy[i][1] = p }
    #check for :nv
    vars_copy.each { |v| puts "Error: unassigned parameter" if v[1] == :nv }
    #add vars as variables to new scope
    vars_copy.each { |v| new_scope.set_var( v[0], v[1].evaluate( scope ) ) }

    @block.evaluate( new_scope )
  end
end

# Node for function calls.
class FunctionCallNode
  def initialize( name, params )
    @name, @params = name, params
  end

  def evaluate( scope )
    #---"builtin" printline for now
    if @name == "pl"
      @params.each { |p| puts p.evaluate( scope ) }
      return
    end
    #----

    func = scope.get_func( @name )
    if func != nil
      func.evaluate( scope, @params )
    else
      puts "Error: no function found."
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

# Node for a for loop.
class ForNode
  def initialize( comp, inc, block, assign = nil )
    @comp, @inc, @block, @assign = comp, inc, block, assign
  end

  def evaluate( scope )
    if assign != nil
      assign.each { |k,v| scope.set_var( k, v ) }
    end

    while( @comp.evaluate( scope ) )
      new_scope = Scope.new( scope )
      @block.evaluate( new_scope )
      @inc.evaluate( scope )
    end
  end
end

# Node for a while loop.
class WhileNode
  def initialize( comp, block )
    @comp, @block = comp, block
  end

  def evaluate( scope )
    while @comp.evaluate( scope )
      new_scope = Scope.new( scope )
      @block.evaluate( new_scope )
    end
  end
end

# Node for an if-statement
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
  def initialize( var, value )
    @name, @value = var.name, value
  end

  def evaluate( scope )
      scope.set_var( @name, @value.evaluate( scope ) )
  end
end

# Node for getting the value from a variable.
class VariableNode
  attr_reader :name

  def initialize( name )
    @name = name
  end

  def evaluate( scope )
    value = scope.get_var( @name )
    if value != nil
      return value
    else
      puts "Error: no variable \"#{@name}\" found."
    end
  end
end


# Node representing an array.
class ArrayNode
  def initialize( array )
    @array = array
  end

  def evaluate( scope )
    return_array = []
    @array.each { |e| return_array << e.evaluate( scope ) }
    return_array
  end
end

# Node representing a constant.
class ConstantNode
  def initialize( value )
    @value = value
  end

  def evaluate( scope )
    @value
  end
end
