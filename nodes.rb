require './builtins'

class Scope

  def initialize( upper_scope = nil )
    @upper = upper_scope
    @vars = {}
    @funcs = {}
  end

  def set_var(name, value, outer = false)
    if !outer then return @vars[name] = value
    elsif @upper.key?(name)
      return @upper.set_var(name, value)
    else
      return @upper.set_var(name, value, true)
    end
  end

  # recursively get variables through upper scopes if not found
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

  def key?(name)
    @vars.key? name
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

# Node for a block of code within brackets.
class BlockNode < SHLProgramNode
  def evaluate( scope )
    new_scope = Scope.new( scope )
    @statements.each { |s| s.evaluate( new_scope ) }
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

    # deep copy of vars to preserve values.
    vars_copy = Array.new
    @vars.each { |e| vars_copy.push(e.dup) }

    # add param values to vars
    params.each_with_index { |p,i| vars_copy[i][1] = p }
    # check for :nv
    vars_copy.each { |v| puts 'Error: unassigned parameter' if v[1] == :nv }
    # add vars as variables to new scope
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



# Node for a for loop.
class ForNode
  def initialize( comp, inc, block, assign = nil )
    @comp, @inc, @block, @assign = comp, inc, block, assign
  end

  def evaluate( scope )
    !@assign.nil? && @assign.evaluate(scope)

    while @comp.evaluate(scope)
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
class ConditionalNode
  def initialize(i_block, ei_blocks = [], e_block = nil)
    @i_block = i_block
    @ei_blocks, @e_block = ei_blocks, e_block
  end

  def evaluate(scope)
    return @i_block.evaluate(scope) if @i_block.true?(scope)

    l = -> { !@e_block.nil? && @e_block.evaluate(scope) }
    @ei_blocks.detect(l) { |ei| ei.true?(scope) && ei.evaluate(scope) }
  end
end

# Holds the condition and the body of an ~i/~ei/~e
class IfNode
  def initialize(body, cond = ConstantNode.new(true))
    @body = body
    @cond = cond
  end

  def evaluate(scope)
    @body.evaluate scope
  end

  def true?(scope)
    @cond.evaluate scope
  end
end

# Holds an expression which should evaluate to true or false
class ConditionNode
  def initialize(cond)
    @cond = cond
  end

  def evaluate (scope)
    @cond.evaluate scope
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

# Node for arithmetic operations.
class ArithmeticNode
  def initialize( lhs, rhs, op )
    @lhs, @rhs, @op = lhs, rhs, op
  end

  def evaluate(scope)
    lhs, rhs = @lhs.evaluate(scope), @rhs.evaluate(scope)
    if @op == '/'
      lhs.to_f / rhs.to_f
    elsif @op == '//'
      lhs / rhs
    elsif @op == '**'
      lhs**rhs
    else
      lhs.send(@op, rhs)
    end
  end
end

# Node for assignment, stores a name and a value (node).
class AssignmentNode
  def initialize(var, value, outer = false)
    @name, @value, @outer = var.name, value, outer
  end

  def evaluate(scope)
    scope.set_var(@name, @value.evaluate(scope), @outer)
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

# Node for a hash.
class HashNode
  def initialize( hash )
    @hash = hash
  end

  def evaluate( scope )
    @hash
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
