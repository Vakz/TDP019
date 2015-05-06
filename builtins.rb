def p( a )
  print a
end

def pl( a )
  puts a
end

builtins = {"p" => method(:p), "pl" => method(:pl)}
