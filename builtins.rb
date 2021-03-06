# Built in functions for strings
module StringFuncs
  def self.times(string, x)
    string * x
  end
end

# Built in function for arrays
module ArrayFuncs
  def self.includes(array, element)
    array.include? element
  end

  def self.append(array, element)
    array << element
  end
end

# Built in functions in the global scope
module GeneralFuncs
  def self.p(*args)
    print(*args)
  end

  def self.pl(*args)
    puts(*args)
  end
end

# Built in functions for hashes
module HashFuncs
  def self.has_key(hash, element)
    hash.key? element
  end
end

module IntegerFuncs
  def self.is_even(int)
    int.even?
  end
end

module Builtins
  General = { 'p' => GeneralFuncs.method(:p),
              'pl' => GeneralFuncs.method(:pl) }
  String = { 'times' => StringFuncs.method(:times) }
  Array = { 'includes' => ArrayFuncs.method(:includes),
             'append' => ArrayFuncs.method(:append)}
  Hash = { 'has_key' => HashFuncs.method(:has_key) }
  Fixnum = { 'is_even' => IntegerFuncs.method(:is_even) }
end
