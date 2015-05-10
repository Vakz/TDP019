require './nodes'

# Function handle any if-statements with option ifelse and else
def if_statement_handler(if_body, if_cond, elseif = [], e = nil)
  if_node = IfBlock.new(if_body, ConditionNode.new(if_cond))
  IfNode.new(if_node, elseif, e.nil? ? e : IfBlock.new(e))
end
