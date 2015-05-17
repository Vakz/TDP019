def p(*a)
  #a.each do |l|
  #  print a.evaluate(scope)[1]
  #end
end

def pl(*a)
  #a.each do |l|
  #  puts a.evaluate(scope)[1]
  #end
end

module Builtins
  General = {"p" => method(:p), "pl" => method(:pl)}
  @string = {}
  @array = {}
  @hash = {}
end
