#! /usr/bin/ruby
# coding: utf-8
require './rdparse'
require './nodes'

class SHLParse
  def initialize
    @shlp = Parser.new('shorthand language') do

      # LEXER
      token(/\s+/)
      # token(/#.*$/) # Borde hantera alla en-rads kommentarer
      token(/\d+\.\d+/) { |m| m.to_f }	# float
      token(/\d+/)      { |m| m.to_i }	# int
      token(/"[A-Za-z ]*"/) { |m| m } 	# strings
      token(/[A-Za-z]+/) { |m| m }      # identifier
      token(/:[ifsah]/) { |m| m } # type assignments
      token(%r{<=|==|\*\*|//|->|>=|\!=|&&|\|\|}) { |m| m }
      token(/./) { |m| m }              # symbol

      # PARSER
      start :begin do
        match(:stmt_list) { |a| SHLProgramNode.new(a) }
      end

      rule :stmt_list do
        match(:stmt, :stmt_list) { |a, b| [a].concat(b) }
        match(:stmt) { |a| [a] }
      end

      rule :stmt do
        match(:expr, ';') { |a, _| a }
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
        match(:identifier, '(', :arg_list, ')')
        match(:identifier, '(', ')') { |a, _, _| a }
      end

      rule :if_stmt do
        match('~i', :expr, :cond_body, :elseif_list,  '~e', :cond_body)
        match('~i', :expr, :cond_body, :elseif_list)
        match('~i', :expr, :cond_body, '~e', :cond_body)
        match('~i', :expr, :cond_body)
      end

      rule :elseif_list do
        match(:elseif_list, :elseif)
        match(:elseif)
      end

      rule :elseif do
        match('~ei', :expr, :cond_body)
      end

      rule :for_stmt do
        match('~f', :assignment, ';', :expr, ';', :expr, :cond_body)
        match('~f', :expr, ';', :expr, :cond_body)
      end

      rule :while_stmt do
        match('~w', :expr, :cond_body)
      end

      rule :cond_body do
        match('{', :stmt_list, '}')
        match(:stmt)
      end

      rule :arg_list do
        match(:expr, ',', :arg_list)
        match(:expr)
      end

      rule :param_list do
        match(:identifier, ',', :param_def_list)
        match(:identifier, ',', :param_list)
        match(:param_def_list)
        match(:identifier)
      end

      rule :param_def_list do
        match(:identifier, '=', :expr, ',', :param_def_list)
        match(:identifier, '=', :expr)
      end

      rule :class_def do
        match('§', :identifier, '{', :stmt_list, '}')
      end

      rule :function_def do
        match('@', :identifier, '(', :param_list, ')', '{', :stmt_list, '}')
        match('@', :identifier, '(', ')', '{', :stmt_list, '}')
      end

      rule :identifier do
        match(:identifier, '.', :identifier)
        match(:identifier, '[', :identifier, ']')
        match(:identifier, '[', :type, ']')
        match(:name) { '3' }
      end

      rule :name do
        match(/[A-Za-z]+/) { |a| a }
        # match( /_?[[:alpha:]][\w_]*/ )
      end

      rule :unary_op do
        match('++')
        match('--')
      end

      rule :comp_op do
        match('<')
        match('>')
        match('<=')
        match('>=')
        match('==')
        match('!=')
      end

      rule :comparison do
        match(:arith_expr, :comp_op, :arith_expr) { |a, op, b| a.send(op, b) }
      end

      rule :type_dec do
        match(':i')
        match(':f')
        match(':s')
        match(':a')
        match(':h')
      end

      rule :arith_op do
        match('+')
        match('-')
      end

      rule :arith_expr do
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
        match(:identifier, '=', :expr) { |_, _, c| c }
      end

      rule :type_assignment do
        match(:identifier, :type_dec)
      end

      rule :return do
        match('<-', :expr)
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
        match('[', :arg_list, ']')
        match('[', ']')
      end

      rule :string do
        match(/"[A-Za-z ]*"/)
      end

      rule :float do
        match(Float)
      end

      rule :int do
        match(Integer) { |a| ConstantNode.new(a) }
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

  def parse(str)
    @shlp.parse str
  end
end

sp = SHLParse.new
f = File.read 'test_program.shl'
program = sp.parse f
puts program.evaluate
