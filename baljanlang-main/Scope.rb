

class Scope

    def initialize()
        @level = 0
        @functions = [[]]
        @variables = [{}]
        @hierarchy = {0 => []}
    end

    #Skapar en ny variabel
    # Om den variabeln vi vill skapa redan finns i det nuvarande scopeet så hämtar vi bara variabeln
    def []= identifier, type
        level = 0
        exists = false
        if(identifier.scope == nil)
            level = @level
        else
            level = identifier.scope
        end
        @variables[level].each do |name, value|
            if(name == identifier.name)
                return false
            end
        end
        
        @variables[level][identifier.name] = type.new()
        return true
    end

    #Hämtar en existerande variabel
    def [] identifier
        variable = nil
        level = 0
        if(identifier.scope == nil)
            level = @level
        else
            level = identifier.scope
        end
        global = false

        # Gå igenom alla scopes tills vi har tittat igenom global scope
        while(not global)
            if(level == 0)
                global = true
            end

            # Gå igenom alla variabler i nuvarande scopet
            @variables[level].each do |name, value|
                if(name == identifier.name)
                    variable = value
                    break
                end
            end

            # Avsluta om vi hittat en variabel
            break if(variable != nil)

            # Hitta nästa scope ovanför det nuvarande
            @hierarchy.each do |parent, scopes|
                if(scopes.include?(level))
                    level = parent
                end
            end
        end

        # Om vi inte hittade en variabel
        if(variable == nil)
            raise RuntimeError.new("Variable #{identifier.name} not found")
        end

        return variable
    end

    #Lägger till en funktion
    def add_function(function)
        @functions.each do |level_funcs|
            level_funcs.each do |func|
                # Samma namn? om inte är allt okej
                next if(func.name != function.name)
                
                # Samma returtyp?
                # Får inte vara två funktioner med samma namn men olika returtyper
                if(func.return_type != function.return_type)
                    raise SyntaxError.new("Functions with the same name must have the same return type")
                end

                # Lika många parametrar? Om inte är allt okej
                next if(function.params.length != func.params.length)

                # Samma parametrar?
                same = true
                func.params.each_with_index do |param, index|
                    if(function.params[index].class.is_a?(param.type))
                        same = false
                        break
                    end
                end

                # Är funktionerna likadana, kasta error
                if(same)
                    raise SyntaxError.new("Two identical functions declared")
                end
            end
        end

        # Om allt gick bra, lägg till funktion
        @functions[@level] << function
        return nil
    end

    #Hämtar en funktion som ligger i scope
    def get_function(name, params)
        function = nil
        global = false
        level = @level

        # Gå igenom alla scopes tills vi har tittat igenom global scope
        while(not global)
            if(level == 0)
                global = true
            end

            # Titta igenom alla funktioner i det nuvarande scopet
            level_funcs = @functions[level]
            level_funcs.each do |func|
                # Nästa om olika namn
                next if(func.name != name)
                # Nästa om olika många parametrar
                next if(func.params.length != params.length)

                # Är alla parametrar av samma typ
                same = true
                func.params.each_with_index do |param, index|
                    if(params[index].class.is_a?(param.type))
                        same = false
                        break
                    end
                end

                # Om de är samma, avbryt
                if(same)
                    function = func
                    break
                end
                break if(function != nil)
            end
            break if(function != nil)
            
            # Hitta nästa scope ovanför det nuvarande
            @hierarchy.each do |parent, scopes|
                if(scopes.include?(level))
                    level = parent
                end
            end
        end

        # Om vi inte hittade en funktion, error
        if(function == nil)
            raise RuntimeError.new("Function #{name} not found")
        end
        return function
    end

    #Skapar ett nytt scope
    def add_scope(parent = 0)
        @level += 1
        @functions << []
        @variables << {}
        @hierarchy[parent] << @level
        @hierarchy[@level] = []
        return @level
    end

    #Tar bort ett scope
    def remove_scope()
        @functions.pop()
        @variables.pop()
        @hierarchy.each do |parent, scopes|
            if(scopes.include?(@level))
                scopes.delete(@level)
                break
            end
        end
        @hierarchy.delete(@level)
        @level -= 1
        return @level
    end

end 