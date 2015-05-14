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
    if @funcs.key?(name)
      result = @funcs[name]
    elsif !@upper.nil?
      result = @upper.get_func(name)
    else
      result = nil
    end
    result
  end
end

# Top level node, containing all other nodes.
class SHLProgramNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate
    scope = Scope.new
    @statements.each do |s|
      r = s.evaluate(scope)
      if [:break, :return, :continue].include? r[0]
        fail "Unexpected keyword \"#{r[0].to_s}\""
      end
    end
  end
end

# Node for a block of code within brackets.
class BlockNode < SHLProgramNode
  def evaluate( scope )
    new_scope = Scope.new( scope )
    @statements.each do |s|
      r = s.evaluate(new_scope)
      return r if [:break, :continue, :return].include? r[0]
    end
  end
end

# Node for function definition
class FunctionDefNode
  def initialize(name, vars, block)
    @name, @vars, @block = name, vars, block
  end

  def evaluate(scope)
    scope.add_func(@name, FunctionNode.new(@name, @vars, @block))
    [:ok, nil]
  end
end

# Function node stored in scope
class FunctionNode
  def initialize(name, vars, block)
    @name, @vars, @block = name, vars, block
  end

  def evaluate(scope, params)
    new_scope = Scope.new(scope)

    # deep copy of vars to preserve values.
    vars_copy = []
    @vars.each { |e| vars_copy.push(e.dup) }

    # add param values to vars
    params.each_with_index { |p, i| vars_copy[i][1] = p }
    # check for :nv
    vars_copy.each { |v| puts 'Error: unassigned parameter' if v[1] == :nv }
    # add vars as variables to new scope
    vars_copy.each { |v| new_scope.set_var(v[0], v[1].evaluate(scope)) }

    r = @block.evaluate(new_scope)
    r[0] = :ok if r[0] == :return
    r
  end
end

# Node for function calls.
class FunctionCallNode
  def initialize( name, params )
    @name, @params = name, params
  end

  def evaluate( scope )
    #---"builtin" printline for now
    if @name == 'pl'

      @params.each do |p|
        puts p.evaluate(scope)[1]
      end
      return [:ok, nil]
    end
    #----

    func = scope.get_func(@name)
    if !func.nil?
      return func.evaluate(scope, @params)
    else
      fail 'Error: no function found.'
    end
  end
end



# Node for a for loop.
class ForNode
  def initialize(comp, inc, block, assign = nil)
    @comp, @inc, @block, @assign = comp, inc, block, assign
  end

  def evaluate(scope)
    !@assign.nil? && @assign.evaluate(scope)

    while @comp.evaluate(scope)[1]
      new_scope = Scope.new(scope)
      r = @block.evaluate(new_scope)
      case r[0]
      when :continue
        next
      when :break
        return [:ok, nil]
      when :return
        return r
      end
      @inc.evaluate(scope)
    end
    [:ok, nil]
  end
end

# Node for a while loop.
class WhileNode
  def initialize(comp, block)
    @comp, @block = comp, block
  end

  def evaluate(scope)
    while @comp.evaluate(scope)
      new_scope = Scope.new(scope)
      r = @block.evaluate(new_scope)
      case r[0]
      when :continue
        next
      when :break
        return [:ok, nil]
      when :return
        return r
      end
    end
  end
end

# Node for return, break or continue
class InterruptNode
  def initialize(type, expr = nil)
    @type, @expr = type, expr
  end

  def evaluate(scope)
    val = @expr.nil? ? nil : @expr.evaluate(scope)[1]
    [@type, val]
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
    l = -> { !@e_block.nil? ? @e_block : nil }
    t = @ei_blocks.detect(l) { |ei| ei.true?(scope) }
    !t.nil? ? t.evaluate(scope) : [:ok, nil]
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
    @cond.evaluate(scope)[1]
  end
end

# Holds an expression which should evaluate to true or false
class ConditionNode
  def initialize(cond)
    @cond = cond
  end

  def evaluate(scope)
    [:ok, @cond.evaluate(scope)[1]]
  end
end

# Node for comparisons.
class ComparisonNode
  def initialize(lhs, rhs, op)
    @lhs, @rhs, @op = lhs, rhs, op
  end

  def evaluate(scope)
    [:ok, @lhs.evaluate(scope)[1].send(@op, @rhs.evaluate(scope)[1])]
  end
end

# Node for arithmetic operations.
class ArithmeticNode
  def initialize(lhs, rhs, op)
    @lhs, @rhs, @op = lhs, rhs, op
  end

  def evaluate(scope)
    lhs, rhs = @lhs.evaluate(scope)[1], @rhs.evaluate(scope)[1]
    case @op
    when '/'
      [:ok, lhs.to_f / rhs.to_f]
    when '//'
      [:ok, lhs / rhs]
    else
      [:ok, lhs.send(@op, rhs)]
    end
  end
end

# Node for assignment, stores a name and a value (node).
class AssignmentNode
  def initialize(var, value, outer = false)
    @value, @outer = value, outer
    if var.class == BracketCallNode
      @name = var
      @array = true
    else
      @name = var.name
    end
  end

  def evaluate(scope)
    if @array
      @name.set(scope, @value)
      [:ok, @value.evaluate(scope)[1]]
    else
      [:ok, scope.set_var(@name, @value.evaluate(scope)[1], @outer)]
    end
  end

end

# Node for getting the value from a variable.
class VariableNode
  attr_reader :name

  def initialize( name )
    @name = name
  end

  def evaluate( scope )
    value = scope.get_var(@name)
    if !value.nil?
      return [:ok, value]
    else
      fail "Error: no variable \"#{@name}\" found."
    end
  end
end

# Used when the bracket operator is called on an identifier
class BracketCallNode

  def initialize(identifier, arg)
    @identifier, @arg = identifier, arg
  end

  def evaluate(scope)
    arg_val = @arg.evaluate(scope)[1]
    var = @identifier.evaluate(scope)[1]
    val = var[arg_val].evaluate(scope)[1]
    [:ok, val]
  end

  def set(scope, value)
    a = @identifier.evaluate(scope)[1]
    a[@arg.evaluate(scope)[1]] = value
  end
end


# Node for a hash.
class HashNode
  def initialize(args = nil)
    @args = args
    @hash = {}
  end

  def evaluate(scope)
    @args.each do |x|
      @hash[x[0].evaluate(scope)[1]] = x[1].evaluate(scope)[1]
    end
    [:ok, @hash]
  end
end
# For arithmetic operations with only one operand, such as "a++"
class UnaryExprNode
  def initialize(val, op, after)
    @val, @op, @after = val, op, after
  end

  def evaluate(scope)
    val = @val.evaluate(scope)[1]
    case @op
    when '-'
      return [:ok, -val]
    when '++', '--'
      scope.set_var(@val.name, val.send(@op[0], 1))
      return [:ok, @after ? val : @val.evaluate(scope)[1]]
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
    @array.each { |e| return_array << e }
    [:ok, return_array]
  end
end
# Node representing a cast
class ConversionNode
  def initialize(value, type)
    @value, @type = value, type
  end

  def evaluate(scope)
    val = @value.evaluate(scope)[1]
    case @type.evaluate(scope)[1]
    when String
      return [:ok, val.to_s]
    when Fixnum
      return [:ok, val.to_i]
    when Float
      return [:ok, val.to_f]
    when FalseClass
      return [:ok, !!val]
    end
  end
end

# Node representing a constant.
class ConstantNode
  def initialize( value )
    @value = value
  end

  def evaluate( scope )
    [:ok, @value]
  end
end
