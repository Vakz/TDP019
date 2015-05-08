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
      token(/#.*$/) # Borde hantera alla en-rads kommentarer
      token(/\d+\.\d+/) { |m| m.to_f }	# float
      token(/\d+/)      { |m| m.to_i }	# int
      token(/"[A-Za-z ]*"/) { |m| m } 	# strings
      token(/[A-Za-z]+/) { |m| m }      # identifier
      token(/:[ifsah]/) { |m| m }       # type assignments
      token(/~ei|~[iewf]/) { |m| m }  # if / loops
      token(/==|<=|>=|!=|\*\*|\/\/|->|&&|\|\|/) { |m| m }
      token(/./) { |m| m }              # symbol

      # PARSER
      start :begin do
        match(:stmt_list) { |sl| SHLProgramNode.new( sl ) }
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
        match('!->', ';')
        match('->!', ';')
      end

      rule :expr do
        match('(', :expr, ')')
        match(:assignment)
        match(:conversion)
        match(:unary_op, :expr)
        match(:expr, :unary_op)
        match(:bool_expr)
        match(:comparison)
        match(:arith_expr)
        match(:expr_call)
        match(:identifier)
        match(:type)
        match('!', :expr) { |_, b| !b }
      end

      rule :conversion do
        match(:identifier, '->', :type_dec) { 3.to_i }
      end

      rule :bool_expr do
        match(:bool_expr, '&&', :expr) { |a, _, b| a && b }
        match(:bool_expr, '||', :expr) { |a, _, b| a || b }
        match(:bool)
      end

      rule :expr_call do
        match(:identifier, '(', :arg_list, ')') { |i, _, al| FunctionCallNode.new( i.name, al )}
        match(:identifier, '(', ')') { |i| FunctionCallNode.new( i.name, [] ) }
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
        match(:elseif_list, :elseif) { |list, ei| ei.concat(list) }
        match(:elseif) { |a| [a] }
      end

      rule :elseif do
        match('~ei', :expr, :cond_body) { |_, c, b| IfBlock.new(b, c) }
      end

      rule :for_stmt do
        match('~f', :assignment, ';', :expr, ';', :expr, :cond_body)
        match('~f', :expr, ';', :expr, :cond_body)
      end

      rule :while_stmt do
        match('~w', :expr, :cond_body)
      end

      rule :cond_body do
        match('{', :stmt_list, '}') { |_, s, _| s }
        match(:stmt) { |x| [x] }
      end

      rule :arg_list do
        match(:expr, ',', :arg_list) { |e,_,al| [e].concat(al) }
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
        match(:identifier, '=', :expr) { |i,_,e| [[i.name,e]] }
      end

      rule :class_def do
        match('§', :identifier, '{', :stmt_list, '}')
      end

      # TODO: Add possibility to create an empty function? Not currently in BNF
      rule :function_def do
        match('@', :identifier, '(', :param_list, ')', '{', :stmt_list, '}') do |_,i,_,pl,_,_,sl|
          FunctionDefNode.new( i.name, pl, BlockNode.new( sl ) )
        end
        match('@', :identifier, '(', ')', '{', :stmt_list, '}') do |_,i,_,_,_,sl|
          FunctionDefNode.new( i.name, [], BlockNode.new( sl ) )
        end
      end

      rule :identifier do
        match(:identifier, '.', :identifier)
        match(:identifier, '[', :identifier, ']')
        match(:identifier, '[', :type, ']')
        match(:name) { |n| VariableNode.new( n ) }
      end

      rule :name do
        match(/[\wÅÄÖåäö][\w\d_åäöÅÄÖ]*/) { |a| a }
      end

      rule :unary_op do
        match('++')
        match('--')
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
        match(:arith_expr, :comp_op, :arith_expr) { |a, op, b| ComparisonNode.new( a,b,op ) }
      end

      rule :type_dec do
        match(':i') { ConstantNode.new( 0 ) }
        match(':f') { ConstantNode.new( 0.0 ) }
        match(':s')
        match(':a')
        match(':h')
      end

      rule :arith_op do
        match('+')
        match('-')
      end

      rule :arith_expr do
        match('(', :arith_expr, ')')
        match(:arith_expr, :arith_op, :term) { |a, op, b| a.send(op, b) }
        match(:term, :arith_op, :term) { |a, op, b| a.send(op, b) }
        match(:term)
      end

      rule :term_op do
        match('//')
        match('*')
        match('/')
      end

      rule :term do
        match(:term, :term_op, :pow) do |a, op, b|
          case op
          when '*'
            a * b
          when '/'
            t = a.to_f / b
            t % 1 == 0 ? t.round : t
          when '//'
            a / b
          end
        end
        match(:pow)
      end

      rule :pow do
        match(:pow, '**', :factor) { |a, _, b| a**b }
        match(:factor)
      end

      rule :factor do
        match('-', :factor) { |_, a| -a }
        match('(', :arith_expr, ')') { |_, b, _| b }
        match(:type)
        match(:expr_call)
        match(:identifier)

      end

      rule :assignment do
        match(:expr_assignment)
        match(:type_assignment)
      end

      rule :expr_assignment do
        match(:identifier, '=', :expr) { |i,_,e| AssignmentNode.new( i, e ) }
      end

      rule :type_assignment do
        match(:identifier, :type_dec) { |i,td| AssignmentNode.new( i, td ) }
      end

      rule :return do
        match('<-', :expr)
        match('<-')
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
        match(:hash_arg, ',', :hash_arg_list)
        match(:hash_arg)
      end

      rule :hash_arg do
        match(:identifier, ':', :identifier)
      end

      rule :hash do
        match('{', :hash_arg_list, '}')
        match('{', '}')
      end

      rule :array do
        match('[', :arg_list, ']') { |_,al| ArrayNode.new( al ) }
        match('[', ']') { ArrayNode.new( Array.new )}
      end

      rule :string do
        match(/"[^"]*"/) { |s| ConstantNode.new( s ) }
      end

      rule :float do
        match(Float) { |f| ConstantNode.new( f ) }
      end

      rule :int do
        match(Integer) { |i| ConstantNode.new( i ) }
      end

      rule :bool do
        match('true') { ConstantNode.new( true ) }
        match('false') { ConstantNode.new( false ) }
      end

      rule :nil do
        match('nil') { ConstantNode.new( nil ) }
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
f = File.read 'test_program.shl'
sp.log(false)
program = sp.parse f
program.evaluate
