require './nodes'

# Function handle any if-statements with option ifelse and else
def if_statement_handler(if_body, if_cond, elseif = [], e = nil)
  #puts "TEST"
  #puts e.inspect
  if_node = IfBlock.new(if_body, ConditionNode.new(if_cond))
  IfNode.new(if_node, elseif, IfBlock.new(e))
end
