#! /usr/bin/ruby
# coding: utf-8
require './rdparse'
require './nodes'
require './helpers'

class SHLParse
  def initialize
    @shlp = Parser.new('shorthand language') do

      # LEXER
      token(/\s+/)
      token(/#>[^<]*<#/)                # start-stop comment
      token(/#.*$/)                     # single line comment
      token(/\d+\.\d+/) { |m| m.to_f }	# float
      token(/\d+/)      { |m| m.to_i }	# int
      token(/"[^"]*"/) { |m| m }      	# strings
      token(/[\wÅÄÖåäö][\w\d_åäöÅÄÖ]*/) { |m| m } # identifiers
      token(/:[ifsahb]/) { |m| m }      # type assignments
      token(/~ei|~[iewf]/) { |m| m }    # if / loops
      token(/\!->|->\!/) { |m| m }      # interrupt keywords
      token(/==|<=|>=|!=|\*\*|\/\/|<-|->|\+\+|--|&&|\|\|/) { |m| m }
      token(/./) { |m| m }              # symbol

      # PARSER
      start :begin do
        match(:stmt_list) { |sl| SHLProgramNode.new(sl) }
      end

      rule :stmt_list do
        match(:stmt, :stmt_list) { |s, sl| [s].concat(sl) }
        match(:stmt) { |s| [s] }
      end

      rule :stmt do
        match(:expr, ';') { |s, _| s }
        match(:if_stmt)
        match(:for_stmt)
        match(:while_stmt)
        match(:class_def)
        match(:function_def)
        match(:return, ';')
        match('!->', ';') { InterruptNode.new(:continue) } # continue
        match('->!', ';') { InterruptNode.new(:break) } # break
      end

      rule :expr do
        match('(', :expr, ')')
        match(:assignment)
        match(:conversion)
        match(:bool_expr)
        match(:comparison)
        match(:arith_expr)
        match(:expr_call)
        match(:identifier)
        match(:type)
        match('!', :expr) { |_, b| !b }
      end

      rule :unary_expr do
        match(:unary_op, :identifier) { |op, expr| UnaryExprNode.new(expr, op, false) }
        match(:identifier, :unary_op) { |expr, op| UnaryExprNode.new(expr, op, true) }
      end

      rule :conversion do
        match(:identifier, '->', :type_dec) do |i, _, t|
          ConversionNode.new(i, t)
        end
      end

      rule :bool_expr do
        match(:bool_expr, '&&', :expr) { |a, _, b| a && b }
        match(:bool_expr, '||', :expr) { |a, _, b| a || b }
        match(:bool)
      end

      rule :expr_call do
        match(:identifier, '(', :arg_list, ')') { |i, _, al| CallNode.new(i, al)}
        match(:identifier, '(', ')') { |i| CallNode.new(i, []) }
      end

      rule :if_stmt do
        match('~i', :expr, :cond_body, :elseif_list,  '~e', :cond_body) \
        do |_, i_cond, i_body, elseifs, _, e_body|
          if_statement_handler(i_body, i_cond, elseifs, e_body)
        end

        match('~i', :expr, :cond_body, :elseif_list) \
        do |_, i_cond, i_body, elseifs|
          if_statement_handler(i_body, i_cond, elseifs)
        end

        match('~i', :expr, :cond_body, '~e', :cond_body) \
        do |_, i_cond, i_body, _, e_body|
          if_statement_handler(i_body, i_cond, [], e_body)
        end

        match('~i', :expr, :cond_body) { |_, c, b| if_statement_handler(b, c) }
      end

      rule :elseif_list do
        match(:elseif_list, :elseif) { |list, ei| [ei].concat(list) }
        match(:elseif) { |a| [a] }
      end

      rule :elseif do
        match('~ei', :expr, :cond_body) do |_, c, b|
          IfNode.new(BlockNode.new(b), c)
        end
      end

      rule :for_stmt do
        # No version with only assignment exists, as it is impossible
        # to tell whether an assignment is meant to be just an assigment
        # or the condition

        # All specified
        match('~f', :assignment, ';', :expr, ';', :expr, :cond_body) \
        do |_, a, _, c, _, i, body|
          for_statement_handler(body, assignment: a, cond: c, inc: i)
        end
        # Assignment and Condition specified
        match('~f', :assignment, ';', :expr, :cond_body) do
          |_, a, _, c, body|
          for_statement_handler(body, assignment: a, cond: c)
        end
        # Condition and Incement specified
        match('~f', :expr, ';', :expr, :cond_body) do |_, c, _, i, b|
          for_statement_handler(b, cond: c, inc: i)
        end
        # Assignment and Incement specified
        match('~f', :assignment, ';', ';', :expr, :cond_body) do
          |_, a, _, _, i, body|
          for_statement_handler(body, assignment: a, inc: i)
        end
        # Condition specified
        match('~f', :expr, :cond_body) do |_, c, body|
          for_statement_handler(body, cond: c)
        end
        # None specified
        match('~f', :cond_body) do |_, body|
          for_statement_handler(body)
        end
      end

      rule :while_stmt do
        match('~w', :expr, :cond_body) do |_, e, c|
          WhileNode.new(e, BlockNode.new(c))
        end
        match('~w', :cond_body) do |_, c|
          WhileNode.new(ConstantNode.new(true), BlockNode.new(c))
        end
      end

      rule :cond_body do
        match('{', :stmt_list, '}') { |_, s, _| s }
        match(:stmt) { |x| [x] }
      end

      rule :arg_list do
        match(:expr, ',', :arg_list) { |e, _, al| [e].concat(al) }
        match(:expr) { |e| [e] }
      end

      rule :param_list do
        match(:identifier, ',', :param_def_list) { |i,_,pdl| [[i.name,:nv]].concat(pdl) }
        match(:identifier, ',', :param_list) { |i,_,pl| [[i.name,:nv]].concat(pl) }
        match(:param_def_list)
        match(:identifier) { |i| [[i.name,:nv]] }
      end

      rule :param_def_list do
        match(:identifier, '=', :expr, ',', :param_def_list) { |i,_,e,_,pdl| [[i.name,e]].concat(pdl) }
        match(:identifier, '=', :expr) { |i, _, e| [[i.name,e]] }
      end

      rule :class_def do
        match('!', :identifier,'(', :param_list, ')', '{', :stmt_list, '}') do |_,i,_,pl,_,_,sl|
          CallableDefNode.new(i.name, :class, pl, BlockNode.new(sl))
        end
        match('!', :identifier, '{', :stmt_list, '}') do |_,i,_,sl|
          CallableDefNode.new(i.name, :class, [], BlockNode.new(sl))
        end
        match('!', :identifier, '(', ')', '{', :stmt_list, '}') do |_, i, _, _, _, sl|
          CallableDefNode.new(i.name, :class, [], BlockNode.new(sl))
        end
      end

      rule :function_def do
        match('@', :identifier, '(', :param_list, ')', '{', :stmt_list, '}') do |_,i,_,pl,_,_,sl|
          CallableDefNode.new(i.name, :func, pl, BlockNode.new(sl))
        end
        match('@', :identifier, '(', ')', '{', :stmt_list, '}') do |_,i,_,_,_,sl|
          CallableDefNode.new(i.name, :func, [], BlockNode.new(sl))
        end
        match('@', :identifier, '{', :stmt_list, '}') do |_, i, _, sl, _|
          CallableDefNode.new(i.name, :func, [],  BlockNode.new(sl))
        end
      end

      rule :value do
        match(:identifier)
        match(:type)
      end

      rule :identifier do
        match(:identifier, '.', :identifier) { |i1,_,i2| MemberNode.new(i1,i2) }
        match(:identifier, '[', :value, ']') { |n, _, t, _| BracketCallNode.new(n, t) }
        match(:name) { |n| VariableNode.new(n) }
      end

      rule :name do
        match(/[\wÅÄÖåäö][\w\d_åäöÅÄÖ]*/) { |a| a }
      end

      rule :unary_op do
        match('++')
        match(/--/)
      end

      rule :comp_op do
        match('==')
        match('<=')
        match('>=')
        match('!=')
        match('<')
        match('>')
      end

      rule :comparison do
        match(:arith_expr, :comp_op, :arith_expr) do |a, op, b|
          ComparisonNode.new(a, b, op)
        end
      end

      rule :type_dec do
        match(':i') { ConstantNode.new(0) }
        match(':f') { ConstantNode.new(0.0) }
        match(':s') { ConstantNode.new('') }
        match(':a') { ConstantNode.new([]) }
        match(':h') { ConstantNode.new({}) }
        match(':b') { ConstantNode.new(false) }
      end

      rule :arith_op do
        match('+')
        match('-')
      end

      rule :arith_expr do
        match('(', :arith_expr, ')')
        match(:arith_expr, :arith_op, :term) do |a, op, b|
          ArithmeticNode.new(a, b, op)
        end
        match(:term, :arith_op, :term) do |a, op, b|
          ArithmeticNode.new(a, b, op)
        end
        match(:term)
      end

      rule :term_op do
        match('//')
        match('*')
        match('/')
      end

      rule :term do
        match(:term, :term_op, :pow) do |a, op, b|
          ArithmeticNode.new(a, b, op)
        end
        match(:pow)

      end

      rule :pow do
        match(:pow, '**', :factor) { |a, _, b| ArithmeticNode.new(a, b, '**') }
        match(:factor)
      end

      rule :factor do
        match('(', :arith_expr, ')') { |_, b, _| b }
        match('-', :term) { |_, v| UnaryExprNode.new(v, '-', false) }
        match(:unary_expr)
        match(:type)
        match(:expr_call)
        match(:identifier)
      end

      rule :assignment do
        match(:expr_assignment)
        match(:type_assignment)
      end

      rule :expr_assignment do
        match(:identifier, '=', :expr) { |i, _, e| AssignmentNode.new(i, e) }
        match('^', :identifier, '=', :expr) do |_, i, _, e|
          AssignmentNode.new(i, e, true)
        end
      end

      rule :type_assignment do
        match(:identifier, :type_dec) { |i, td| AssignmentNode.new(i, td) }
      end

      rule :return do
        match('<-', :expr) { |_, e| InterruptNode.new(:return, e) }
        match('<-') { InterruptNode.new(:return) }
      end

      rule :type do
        match(:bool)
        match(:int)
        match(:float)
        match(:string)
        match(:array)
        match(:hash)
        match(:nil)
      end

      rule :hash_arg_list do
        match(:hash_arg, ',', :hash_arg_list) { |s, _, l| [s].concat(l) }
        match(:hash_arg) { |x| [x] }
      end

      rule :hash_arg do
        match(:value, ':', :value) { |lhs, _, rhs| [lhs, rhs] }
      end

      rule :hash do
        match('{', :hash_arg_list, '}') { |_, h, _| HashNode.new(h) }
        match('{', '}') { HashNode.new }
      end

      rule :array do
        match('[', :arg_list, ']') { |_,al| ArrayNode.new(al) }
        match('[', ']') { ArrayNode.new(Array.new) }
      end

      rule :string do
        # Remove quotes around string
        match(/"[^"]*"/) { |s| ConstantNode.new(s[1, s.length - 2]) }
      end

      rule :float do
        match(Float) { |f| ConstantNode.new(f) }
      end

      rule :int do
        match(Integer) { |i| ConstantNode.new(i) }
      end

      rule :bool do
        match('true') { ConstantNode.new(true) }
        match('false') { ConstantNode.new(false) }
      end

      rule :nil do
        match('nil') { ConstantNode.new(nil) }
      end
    end
  end

  def log(state = true)
    if state
      @shlp.logger.level = Logger::DEBUG
    else
      @shlp.logger.level = Logger::WARN
    end
  end

  def parse(str)
    @shlp.parse str
  end
end

sp = SHLParse.new
f = File.read ARGV[0].nil? ? 'test_program.shl' : ARGV[0]
sp.log(false)
program = sp.parse f
program.evaluate
