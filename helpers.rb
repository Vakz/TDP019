require './nodes'

# Function handle any if-statements with option ifelse and else
def if_statement_handler(if_body, if_cond, elseif = [], e = nil)
  if_node = IfNode.new(BlockNode.new(if_body), ConditionNode.new(if_cond))
  ConditionalNode.new(if_node, elseif, e.nil? ? e : IfNode.new(BlockNode.new(e)))
end

def for_statement_handler(body, assignment: nil, \
  cond: ConditionNode.new(ConstantNode.new(true)), inc: ConstantNode.new(nil))
  ForNode.new(cond, inc, BlockNode.new(body), assignment)
end
