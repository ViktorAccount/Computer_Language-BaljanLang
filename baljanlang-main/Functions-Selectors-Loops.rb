require_relative './Variables'


#==================== Functions ====================
# En funktion
class BLFunc
    attr_reader :name, :params, :return_type
    def initialize(name, params, return_type, body)
        @name = name.to_sym
        @params = params
        @return_type = return_type
        @body = body
    end

    # Funktionen lägger till sig själv i scope när eval kallas
    def eval()
        $scope.add_function(self)
    end

    # När BLFuncCall har hittat en funktion så körs eval_body för att evaluera funktionen
    def eval_body()
        @body.each do |stmt|
            tmp = stmt.eval()
            if(tmp.is_a?(BLReturn))
                value = tmp.eval_value()
                if(not value.is_a?(@return_type))
                    raise RuntimeError.new("Value of wrong type being returned from #{@name}")
                end
                return value
            elsif(tmp.is_a?(BLBreak))
                raise RuntimeError.new("Invalid break found in #{@name}")
            elsif(tmp.is_a?(BLContinue))
                raise RuntimeError.new("Invalid continue found in #{@name}")
            end
        end
        raise RuntimeError.new("No return statement found in #{@name}")
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Name: #{@name}"
        puts base + "┠─Type: #{@return_type}"
        puts base + '┠─Params'
        @params.each_with_index do |val, index|
            if(index != @params.length + 1)
                print base + '┃ ┠─'
                val.tree(base + '┃ ┃ ')
            else
                print base + '┃ ┖─'
                val.tree(base + '┃   ')
            end
        end
        puts base + '┖─Body'
        @body.each_with_index do |val, index|
            if(index + 1 < @body.length)
                print base + '  ┠─'
                val.tree(base + '  ┃ ')
            else
                print base + '  ┖─'
                val.tree(base + '    ')
            end
        end
    end
end

# Kör en funktion som existerar i scope
class BLFuncCall
    def initialize(name, params=[])
        @name = name.to_sym
        @params = params
    end

    # Hämtar en funktion, kör funktionen och returnerar funktionens returvärde
    def eval()
        # Evaluerar alla parametrar
        evaled_params = []
        @params.each do |param|
            evaled_params << param.eval()
        end

        # Hämtar funktionen
        func = $scope.get_function(@name, evaled_params)

        # Skapar ett nytt scope för funktionen
        $scope.add_scope()

        # Lägger till alla parametrarna i det nya scopet
        func.params.each_with_index do |param, index|
            var = param.eval()
            var.value = evaled_params[index].value
        end

        # Evaluera funktionen
        value = func.eval_body()

        # Ta bort funktionens scope och returnera returvärdet
        $scope.remove_scope()
        return value
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Name: #{@name}"
        puts base + '┖─Params'
        @params.each_with_index do |val, index|
            if(index + 1 < @params.length)
                print base + '  ┠─'
                val.tree(base + '  ┃ ')
            else
                print base + '  ┖─'
                val.tree(base + '    ')
            end
        end
    end
end

#==================== Loops ====================
# While loop
class BLWhile
    def initialize(selector, body)
        @selector = selector
        @body = body
    end

    # Kör whileloopen
    def eval()
        # Evaluera selector och titta att det är en bool
        run = @selector.eval()
        if(not run.is_a?(BLBool))
            raise RuntimeError.new("Selector statement in while needs to evaluate to a bool")
        end

        # Evaluera kroppen
        while(run.value)
            @body.each do |stmt|
                tmp = stmt.eval()
                if(tmp.is_a?(BLReturn))
                    return tmp
                elsif(tmp.is_a?(BLBreak))
                    return nil
                elsif(tmp.is_a?(BLContinue))
                    break
                end
            end
            run = @selector.eval()
        end
        return nil
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Selector"
        print base + '┃ ┖─'
        @selector.tree(base + '┃   ')
        puts base + '┖─Body'
        @body.each_with_index do |val, index|
            if(index + 1 < @body.length)
                print base + '  ┠─'
                val.tree(base + '  ┃ ')
            else
                print base + '  ┖─'
                val.tree(base + '    ')
            end
        end
    end
end

# For loop
class BLFor
    def initialize(init, selector, increment, body)
        @init = init
        @selector = selector
        @increment = increment
        @body = body
    end

    def eval()
        # Evaluera de två första argumenten och titta om det andra är en bool
        @init.eval()
        run = @selector.eval()
        if(not run.is_a?(BLBool))
            raise RuntimeError.new("Selector statement in for needs to evaluate to a bool")
        end

        # Evaluera kroppen
        while(run.value)
            @body.each do |stmt|
                tmp = stmt.eval()
                if(tmp.is_a?(BLReturn))
                    return tmp
                elsif(tmp.is_a?(BLBreak))
                    return nil
                elsif(tmp.is_a?(BLContinue))
                    break
                end
            end
            # Evaluera det tredje argumentet och sedan selectorn
            @increment.eval()
            run = @selector.eval()
        end
        return nil
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Init"
        print base + '┃ ┖─'
        @init.tree(base + '┃   ')
        puts base + "┠─Selector"
        print base + '┃ ┖─'
        @selector.tree(base + '┃   ')
        puts base + "┠─Increment"
        print base + '┃ ┖─'
        @increment.tree(base + '┃   ')
        puts base + '┖─Body'
        @body.each_with_index do |val, index|
            if(index + 1 < @body.length)
                print base + '  ┠─'
                val.tree(base + '  ┃ ')
            else
                print base + '  ┖─'
                val.tree(base + '    ')
            end
        end
    end
end



#==================== Selectors ====================
# If sats
class BLIf
    def initialize(selector, body, otherwise=nil)
        @selector = selector
        @body = body
        @otherwise = otherwise
    end

    # Evaluera if satsen
    def eval()
        # Evaluera och titta att selectorn är en bool
        sel = @selector.eval()
        if(not sel.is_a?(BLBool))
            raise RuntimeError.new("Selector statement in if needs to evaluate to a bool")
        end
        # Evaluera kroppen om det är sant
        if(sel.value)
            @body.each do |stmt|
                tmp = stmt.eval()
                if(tmp.is_a?(BLReturn))
                    return tmp
                elsif(tmp.is_a?(BLBreak))
                    return nil
                elsif(tmp.is_a?(BLContinue))
                    break
                end
            end
        # Annars evaluera nästa selector om det finns en
        elsif(@otherwise != nil)
            return @otherwise.eval()
        end
        return nil
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Selector"
        print base + '┃ ┖─'
        @selector.tree(base + '┃   ')
        base2 = base
        if(@otherwise != nil)
            puts base + '┠─Body'
            base2 += '┃ '
        else
            puts base + '┖─Body'
            base2 += '  '
        end
        @body.each_with_index do |val, index|
            if(index + 1 < @body.length)
                print base2 + '┠─'
                val.tree(base2 + '┃ ')
            else
                print base2 + '┖─'
                val.tree(base2 + '  ')
            end
        end
        if(@otherwise != nil)
            print base + '┖─'
            @otherwise.tree(base + '  ')
        end
    end
end

# Else sats
class BLElse
    def initialize(body)
        @body = body
    end
    # Evaluerar kroppen
    def eval()
        @body.each do |stmt|
            tmp = stmt.eval()
            if(tmp.is_a?(BLReturn))
                return tmp
            elsif(tmp.is_a?(BLBreak))
                return nil
            elsif(tmp.is_a?(BLContinue))
                break
            end
        end
    end
    def tree(base = "")
        puts self.class.name
        puts base + '┖─Body'
        base += '  '
        @body.each_with_index do |val, index|
            if(index + 1 < @body.length)
                print base + '┠─'
                val.tree(base + '┃ ')
            else
                print base + '┖─'
                val.tree(base + '  ')
            end
        end
    end
end

#==================== Control ====================
# Basklass för alla control statements
class NAControl
    # Vanlig eval returnerar bara sig själv
    def eval()
        return self
    end
    def tree(base = "")
        puts self.class.name
    end
end

class BLReturn < NAControl
    def initialize(value)
        @value = value
    end
    
    # Returnerar returvärdet
    def eval_value()
        return @value.eval()
    end
    
    def tree(base = "")
        puts self.class.name
        print base + '┖─'
        @value.tree(base + '  ')
    end
end

class BLBreak < NAControl
    
end

class BLContinue < NAControl

end

#==================== Print ====================
class BLPrint
    attr_accessor :value
    def initialize(value = nil)
        @value = value
    end

    def eval()
        # Om print har ett värde
        if(@value != nil)
            # Evaluera värdet och skriv ut det
            res = @value.eval()
            res.output()
        end
        # Skriv ut en newline
        puts
        return nil
    end
    def tree(base = "")
        puts self.class.name
        if(@value != nil)
            print base + '┖─'
            @value.tree(base + '  ')
        end
    end
end