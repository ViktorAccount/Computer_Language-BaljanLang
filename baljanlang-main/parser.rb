require_relative './rdparse.rb'
require_relative './Variables.rb'
require_relative './Functions-Selectors-Loops.rb'
require_relative './Operators.rb'

class BaljanLang
    def initialize
        @parser = Parser.new("BaljanLang") do

            token(/\s+/)
            token(/\/\*.*\*\//)

            token(/int\b/) {|_|:BLInteger}
            token(/float\b/) {|_|:BLFloat}
            token(/bool\b/) {|_|:BLBool}
            token(/char\b/) {|_|:BLChar}
            token(/list\b/) {|_|:BLList}
            token(/string\b/) {|_|:BLString}

            token(/==/){|m|m}
            token(/!=/){|m|m}
            token(/>=/){|m|m}
            token(/<=/){|m|m}
            token(/&&/){|m|m}
            token(/\|\|/){|m|m}

            token(/\d+\.\d+/){|m|m}
            token(/\d+/){|m|m}
            token(/'.'/){|m|m}
            
            token(/".*"/){|m|m}

            token(/[a-zA-Z]\w*/){|m|m}

            token(/./){|m|m}

            start :program do
                match(:def_list){|m|m + [BLFuncCall.new(:main)]}
            end

            rule :def_list do
                match(:def, :def_list){|a, b| a + b}
                match(:def) {|m|m}
            end

            rule :def do
                match(:func_def){|m|[m]}
                match(:assignment, :end_line){|m|[m]}
                match(:var_init, :end_line){|m|[m]}
            end

            rule :func_def do
                match(:data_type, :name, '(', :func_param_list, ')', :begin, :stmt_list, :end){|type,name,_,params,_,_,body,_|BLFunc.new(name, params, type, body)}
                match(:data_type, :name, '(', ')', :begin, :stmt_list, :end){|type,name,_,_,_,body,_|BLFunc.new(name, [], type, body)}
                match(:data_type, :name, :begin, :stmt_list, :end){|type,name,_,body,_|BLFunc.new(name, [], type, body)}
            end

            rule :func_param_list do
                match(:var_init, ',', :func_param_list){|m,_,l|[m] + l}
                match(:var_init){|m|[m]}
            end

            rule :variable do
                match(:variable, '[', :arithmetic_expression, ']'){|base,_,params,_|BLMemberCall.new(base, 'index', [params])}
                match(:var_init){|m|m}
                match(:var){|m|m}
            end

            rule :var_init do
                match(:data_type, '<', :data_type, '>', :var){|type,_,extra,_,id|BLVariableInit.new(type, id, extra)}
                match(:data_type, :var){|type,id|BLVariableInit.new(type, id)}
            end

            rule :var do
                match(:name){|id|BLIdentifier.new(id)}
            end

            rule :stmt_list do
                match(:stmt, :stmt_list){|a,b|a + b}
                match(:stmt){|m|m}
            end

            rule :stmt do
                match(:assignment, :end_line){|m,_|[m]}
                match(:var_init, :end_line){|m,_|[m]}
                match(:controll_stmt, :end_line){|m,_|[m]}
                match(:print, :end_line){|m,_|[m]}
                match(:if_stmt){|m,_|[m]}
                match(:for_stmt){|m,_|[m]}
                match(:while_stmt){|m,_|[m]}
                match(:func_call, :end_line){|m,_|[m]}
                match(:expression, :end_line){|m,_|[m]}
            end

            rule :func_call do
                match(:name, '(', :expression_list, ')'){|name,_,params,_|BLFuncCall.new(name, params)}
                match(:name, '(', ')'){|name,_,_|BLFuncCall.new(name, [])}
            end

            rule :controll_stmt do
                match('break'){|_|BLBreak.new()}
                match('continue'){|_|BLContinue.new()}
                match('return', :expression){|_,value|BLReturn.new(value)}
            end

            rule :print do
                match('print', :expression){|_,value|BLPrint.new(value)}
                match('print'){|_|BLPrint.new()}
            end

            rule :for_stmt do
                match('for', '(', :assignment, :end_line, :expression, :end_line, :assignment, ')', :begin, :stmt_list, :end) do |_,_,init,_,selector,_,increment,_,_,body,_|
                    BLFor.new(init, selector, increment, body)
                end
            end

            rule :while_stmt do
                match('while', '(', :expression, ')', :begin, :stmt_list, :end) do |_,_,selector,_,_,body,_|
                    BLWhile.new(selector, body)
                end
            end

            rule :if_stmt do
                match('if', '(', :expression, ')', :begin, :stmt_list, :end, :else_stmt){|_,_,selector,_,_,body,_,else_stmt|BLIf.new(selector, body, else_stmt)}
                match('if', '(', :expression, ')', :stmt, :else_stmt){|_,_,selector,_,body,else_stmt|BLIf.new(selector, body, else_stmt)}
                match('if', '(', :expression, ')', :begin, :stmt_list, :end){|_,_,selector,_,_,body,_|BLIf.new(selector, body)}
                match('if', '(', :expression, ')', :stmt){|_,_,selector,_,body|BLIf.new(selector, body)}
            end

            rule :else_stmt do
                match('else', :begin, :stmt_list, :end){|_,_,body,_|BLElse.new(body)}
                match('else', :stmt){|_,body|BLElse.new(body)}
            end

            rule :expression_list do
                match(:expression, ',', :expression_list){|a,_,b|[a]+b}
                match(:expression){|m|[m]}
            end

            rule :assignment do
                match(:variable, '=', :multi_assignment){|var,_,value|BLAssignment.new(var, value)}
            end

            rule :multi_assignment do
                match(:variable, '=', :multi_assignment){|var,_,value|BLAssignment.new(var, value)}
                match(:expression){|m|m}
            end

            rule :expression do
                match(:expression, :logic_operator, :comparison_expression){|left,op,right|BLLogicOperator.new(left, right, op)}
                match('!', :expression){|_,right|BLNegate.new(right)}
                match(:comparison_expression){|m|m}
            end

            rule :logic_operator do
                match('||'){|m|m}
                match('&&'){|m|m}
            end

            rule :comparison_expression do
                match(:comparison_expression, :comparison_operator, :arithmetic_expression){|left,op,right|BLComparison.new(left, right, op)}
                match(:arithmetic_expression)
            end

            rule :comparison_operator do
                match('<'){|m|m}
                match('>'){|m|m}
                match('<='){|m|m}
                match('>='){|m|m}
                match('=='){|m|m}
                match('!='){|m|m}
            end

            rule :arithmetic_expression do
                match(:arithmetic_expression, :arithmetic_operator_a, :term){|left,op,right|BLMemberCall.new(left, op, [right])}
                match(:term)
            end

            rule :arithmetic_operator_a do
                match('+'){|_|'addition'}
                match('-'){|_|'subtraction'}
            end

            rule :term do
                match(:term, :arithmetic_operator_b, :mod_pow_expression){|left,op,right|BLMemberCall.new(left, op, [right])}
                match(:mod_pow_expression)
            end

            rule :arithmetic_operator_b do
                match('*'){|_|'multiplication'}
                match('/'){|_|'divition'}
            end

            rule :mod_pow_expression do
                match(:mod_pow_expression, :arithmetic_operator_c, :member_call){|left,op,right|BLMemberCall.new(left, op, [right])}
                match(:member_call)
            end

            rule :arithmetic_operator_c do
                match('^'){|_|'power'}
                match('%'){|_|'modulo'}
            end

            rule :member_call do
                match(:member_call, '.', :name, '(', :expression_list, ')'){|base,_,name,_,params,_|BLMemberCall.new(base, name, params)}
                match(:member_call, '.', :name, '(', ')'){|base,_,name,_,_|BLMemberCall.new(base, name, [])}
                match(:member_call, '[', :arithmetic_expression, ']'){|base,_,params,_|BLMemberCall.new(base, 'index', [params])}
                match(:atom)    
            end

            rule :atom do
                match('(', :expression, ')'){|_,m,_|m}
                match('-', :arithmetic_expression){|_,m|BLNegative.new(m)}
                match(:func_call){|m|m}
                match(:value){|m|m}
                match(:var){|m|m}
            end

            rule :value do
                match(:float)
                match(:integer)
                match(:bool)
                match(:char)  
                match(:string)
            end

            rule :float do
                match(/\A\d+\.\d+\Z/){|m|BLFloat.new(m.to_f)}
            end

            rule :integer do
                match(/\A\d+\Z/){|m|BLInteger.new(m.to_i)}
            end

            rule :bool do
                match('true'){|_|BLBool.new(true)}
                match('false'){|_|BLBool.new(false)}
            end

            rule :char do
                match(/\A'.'\Z/){|m|
                    m = m.delete('\'')
                    BLChar.new(m)
                }
            end

            rule :string do
                match(/\A".*"\Z/) do |match|
                    match = match.delete('"')
                    string = BLString.new()
                    list = []
                    match.each_char do |m|
                        list << BLChar.new(m)
                    end
                    string.value = list
                    string
                end
            end

            rule :data_type do
                match(:BLInteger){|m|BLInteger}
                match(:BLFloat){|m|BLFloat}
                match(:BLBool){|m|BLBool}
                match(:BLChar){|m|BLChar}
                match(:BLList){|m|BLList}
                match(:BLString){|m|BLString}
            end

            rule :name do
                match(/\A[a-zA-Z]\w*\Z/){|m|m}
            end

            rule :begin do
                match('begin')
                match('do')
                match('{')
            end

            rule :end do
                match('end')
                match('}')
            end

            rule :end_line do
                match(';')
            end
        end
    end

    # For parsing a simple string
    def parse_string(string)
        if(@parser.logger.level == Logger::DEBUG)
            puts "=============== Beginning parsing of string ==============="
        end
        @program = @parser.parse(string)
        if(@parser.logger.level == Logger::DEBUG)
            puts "=============== Parsing of string done ==============="
        end
    end

    # For parsing a file
    def parse_file(filename)
        if(!filename.end_with?(".bl"))
            raise "File does not have the correct file-ending"
        elsif(!File.exists?(filename))
            raise "Could not find the given file"
        end

        if(@parser.logger.level == Logger::DEBUG)
            puts "=============== Beginning parsing of file ==============="
        end
        file = File.read(filename)
        @program = @parser.parse(file)
        if(@parser.logger.level == Logger::DEBUG)
            puts "=============== Parsing of file done ==============="
        end
    end

    # Print the program as a tree structure
    def tree()
        @program.each_with_index do |param, index|
            if(index + 1 < @program.length) 
                print '┠─' 
                param.tree('┃ ')
            else 
                print '┖─'
                param.tree('  ')
            end
        end
    end

    # Runs the program
    def run()
        puts "====================================  Running program  ======================================="
        $scope = Scope.new()
        result = nil
        @program.each do |stmt|
            result = stmt.eval()
        end
        print "Output: "
        result.output()
        puts
    end

    def log(state = true)
        if state
          @parser.logger.level = Logger::DEBUG
        else
          @parser.logger.level = Logger::WARN
        end
    end
end

