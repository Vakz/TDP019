require_relative './nodes'

# Function handle any if-statements with option ifelse and else
def if_statement_handler(if_body, if_cond, elseif = [], e = nil)
  if_node = IfNode.new(BlockNode.new(if_body), ConditionNode.new(if_cond))
  ConditionalNode.new(if_node, elseif, e.nil? ? e : IfNode.new(BlockNode.new(e)))
end

def for_statement_handler(body, assignment: nil, \
  cond: ConditionNode.new(ConstantNode.new(true)), inc: ConstantNode.new(nil))
  ForNode.new(cond, inc, BlockNode.new(body), assignment)
end

def call_builtin(var, params, scope)
  # If var is not a MemberNode, call is on a function in the global scope
  if var.class != MemberNode
    if Builtins::General.key?(var.name)
      return [:ok, Builtins::General[var.name].call(*params)]
    end
  end

  # Assume var is MemberNode
  val = var.instance.evaluate(scope)[1]
  c = var.evaluate(scope)[1].class
  hash = { String => Builtins::String,
           Array => Builtins::Array,
           Hash => Builtins::Hash
          }[c]
  if !hash.nil? && hash.key?(var.member.name)
    return [:ok, hash[@node.member.name].call(val, *params)]
  end
  fail "Error: no method \"#{@node.member.name}\" for type \"#{c}\" found."
end

def get_correct_scope(var, scope)
  while var.member.class == MemberNode
    scope = scope.get_var(var.instance.name)
    var = var.member
  end
  var
end
