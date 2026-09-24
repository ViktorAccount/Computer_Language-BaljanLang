require_relative './Variables'

# Basklass för alla unaryOperators
class NAUnaryOperator
    def initialize(value)
        @value = value
    end
    def eval_params()
        return @value.eval()
    end
    def tree(base = "")
        puts self.class.name
        print base + '┖─'
        @value.tree(base + '  ')
    end
end

# Gör ett positivt värde negativt
class BLNegative < NAUnaryOperator
    def eval()
        right = eval_params()
        raise RuntimeError.new("Can only turn numbers negative") if(not right.is_a?(NANumber))
        return right.class.new(-right.value)
    end 
end

# En sanningsvärde negation
class BLNegate < NAUnaryOperator
    def eval()
        right = eval_params()
        raise RuntimeError.new("Can only negate bools") if(not right.is_a?(BLBool))
        return BLBool.new(!right.value)
    end
end

# Basklass för alla binary operators
class NABinaryOperator
    def initialize(left, right, operator=nil)
        @lh = left
        @rh = right
        @operator = operator
    end

    def eval_params()
        return @lh.eval(), @rh.eval()
    end
    def tree(base = "")
        puts self.class.name
        print base + '┠─'
        @lh.tree(base + '┃ ')
        puts base + "┠─op #{@operator}"
        print base + '┖─'
        @rh.tree(base + '  ')
    end
end

# Alla jämförelseoperatorer
class BLComparison < NABinaryOperator
    def eval()
        left, right = eval_params()
        result = left.compare(right)
        case @operator
        when '<'
            return BLBool.new(result == -1)
        when '<='
            return BLBool.new(result < 1)
        when '>'
            return BLBool.new(result == 1)
        when '>='
            return BLBool.new(result > -1)
        when '=='
            return BLBool.new(result == 0)
        when '!='
            return BLBool.new(result != 0)
        else
            raise SyntaxError.new("Invalid comparison operator")
        end
    end
end

# Alla sanningsvärde operatorer
class BLLogicOperator < NABinaryOperator
    def eval()
        left, right = eval_params()
        if((not left.is_a?(BLBool)) or (not right.is_a?(BLBool)))
            raise RuntimeError.new("Logic operator can only work with bools")
        end
        case @operator
        when '&&'
            return BLBool.new(left.value && right.value)
        when '||'
            return BLBool.new(left.value || right.value)
        else
            raise SyntaxError.new("Invalid logic operator")
        end
    end
end

# Tilldelningsoperatorn
class BLAssignment < NABinaryOperator
    def eval()
        left, right = eval_params()
        left.value = right.value
        return right
    end
    def tree(base = "")
        puts self.class.name
        print base + '┠─'
        @lh.tree(base + '┃ ')
        print base + '┖─'
        @rh.tree(base + '  ')
    end
end

# Alla medlemsfunktioner och alla aritmetik operatorer hanteras av BLMemberCall
class BLMemberCall
    def initialize(base, name, params)
        @base = base
        @name = name.to_sym
        @params = params
    end
    def eval()
        evaled_base = @base.eval()
        evaled_params = []
        @params.each do |param|
            evaled_params << param.eval()
        end
        return evaled_base.send(@name, *evaled_params)
    end
    def tree(base = "")
        puts self.class.name
        print base + '┠─'
        @base.tree(base + '┃ ')
        puts base + "┠─Name: #{@name}"
        puts base + '┖─params'
        base += '  '
        @params.each_with_index do |param, index|
            if(index + 1 < @params.length) 
                print base + '┠─' 
                param.tree(base + '  ┃ ')
            else 
                print base + '┖─'
                param.tree(base + '    ')
            end
        end

    end
end
