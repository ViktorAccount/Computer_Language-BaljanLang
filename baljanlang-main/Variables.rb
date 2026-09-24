require_relative './Scope'


#==================== Helper ====================
# Kopiera en klass
def copy(var)
    return Marshal.load(Marshal.dump(var))
end

#==================== Accessors ====================
# En identifierare för variabler, kan innehålla scope för referenser
# Referenser är inte implementerade
class BLIdentifier
    attr_reader :name, :scope
    def initialize(name, scope=nil)
        @name = name
        @scope = scope
    end

    # Hämtar variabel från scope när den evalueras
    def eval()
        return $scope[self]
    end

    def tree(base = "")
        puts self.class.name
        if(scope == nil)
            puts base + "┖─Name: #{@name}"
        else
            puts base + "┠─Name: #{@name}"
            puts base + "┖─Scope: #{@scope}"
        end
    end
end

# Skapae en ny variabel
class BLVariableInit
    attr_reader :type, :identifier, :extra
    def initialize(type, identifier, extra=nil)
        @type = type
        @identifier = identifier
        @extra = extra
    end

    def eval()
        created = $scope[@identifier] = type
        # Om variabeln ska ha någon extra information så lägger vi till det
        if(extra != nil && created)
            $scope[@identifier].type = @extra
        end
        return $scope[@identifier]
    end

    def tree(base = "")
        puts self.class.name
        puts base + "┠─Type: #{@type}"
        puts base + "┠─Extra: #{@extra}"
        print base + '┖─'
        @identifier.tree(base + '  ')
    end
end

#==================== Base ====================
# Basklass för alla variabler
class NAVariable
    attr_reader :value
    def eval()
        return self
    end
    
    # Error ifall vi försöker kalla någon medlemsfunktion som inte existerar
    def method_missing(m, *args)
        raise RuntimeError.new("#{self.class.name} does not support #{m} with args #{args}")
    end
end

#==================== Simple ====================
# En enkel variabel vars data bara är en sak
class NASimple < NAVariable
    attr_reader :value
    # Gemensamt print beteende
    def output()
        print @value
        return nil
    end

    # Enkel jämförelse, kan jämföra två variabler av samma typ
    def compare(other)
        raise RuntimeError.new("#{self.class.name} only supports comparison with self") if(not other.is_a?(self.class))
        return @value <=> other.value
    end

    def tree(base = "")
        puts "#{self.class.name}: #{@value}"
    end
end

# Ett tecken
class BLChar < NASimple
    def initialize(value='')
        if(not value.is_a?(String) && value.length < 2)
            raise RuntimeError.new("Char initialized with wrong type of value")
        end
        @value = value
    end

    def value=(value)
        if(not value.is_a?(String) && value.length < 2)
            raise RuntimeError.new("Char assigned wrong type of value")
        end
        @value = value
        return self
    end

    def tree(base = "")
        puts "#{self.class.name}: '#{@value}'"
    end
end

# Ett sanningsvärde
class BLBool < NASimple
    def initialize(value=false)
        if(not (value.is_a?(TrueClass) || value.is_a?(FalseClass)))
            raise RuntimeError.new("Bool initialized with wrong type of value")
        end
        @value = value
    end

    def value=(value)
        if(not (value.is_a?(TrueClass) || value.is_a?(FalseClass)))
            raise RuntimeError.new("Bool assigned wrong type of value")
        end
        @value = value
        return self
    end
end

# Basklass för alla numer
class NANumber < NASimple
    # Speciel jämförelse så BLInteger kan jämföras med BLFloat och tvärt om
    def compare(other)
        raise RuntimeError.new("#{self.class.name} only supports comparison with other numbers") if(not other.is_a?(NANumber))
        return @value <=> other.value
    end
end

# Ett heltalsvärde
class BLInteger < NANumber
    def initialize(value=0)
        if(not value.is_a?(Integer))
            raise RuntimeError.new("Integer initialized with wrong type of value")
        end
        @value = value
    end

    def value=(value)
        if(not value.is_a?(Integer))
            raise RuntimeError.new("Bool assigned wrong type of value")
        end
        @value = value
        return self
    end

    def self.cast(value)
        if(not value.is_a?(NANumber))
            raise RuntimeError.new("Invalid cast type")
        end
        return BLInteger.new(value.value.to_i)
    end

    # Alla aritmetik operationer
    def addition(rh)
        raise RuntimeError.new("Invalid addition between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value + rh.value).to_i)
    end
    def subtraction(rh)
        raise RuntimeError.new("Invalid subtraction between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value - rh.value).to_i)
    end
    def multiplication(rh)
        raise RuntimeError.new("Invalid multiplication between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value * rh.value).to_i)
    end
    def divition(rh)
        raise RuntimeError.new("Invalid divition between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value / rh.value).to_i)
    end
    def power(rh)
        raise RuntimeError.new("Invalid power between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value ** rh.value).to_i)
    end
    def modulo(rh)
        raise RuntimeError.new("Invalid modulo between BLInteger and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLInteger.new((@value % rh.value).to_i)
    end
end

# Ett flyttalsvärde
class BLFloat < NANumber
    def initialize(value=0.0)
        if(not value.is_a?(Float))
            raise RuntimeError.new("Float initialized with wrong type of value")
        end
        @value = value
    end

    def value=(value)
        if(not value.is_a?(Float))
            raise RuntimeError.new("Bool assigned wrong type of value")
        end
        @value = value
        return self
    end

    def self.cast(value)
        if(not value.is_a?(NANumber))
            raise RuntimeError.new("Invalid cast type")
        end
        return BLInteger.new(value.value.to_f)
    end

    # Alla aritmetik operationer
    def addition(rh)
        raise RuntimeError.new("Invalid addition between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value + rh.value).to_f)
    end
    def subtraction(rh)
        raise RuntimeError.new("Invalid subtraction between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value - rh.value).to_f)
    end
    def multiplication(rh)
        raise RuntimeError.new("Invalid multiplication between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value * rh.value).to_f)
    end
    def divition(rh)
        raise RuntimeError.new("Invalid divition between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value / rh.value).to_f)
    end
    def power(rh)
        raise RuntimeError.new("Invalid power between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value ** rh.value).to_f)
    end
    def modulo(rh)
        raise RuntimeError.new("Invalid modulo between BLFloat and #{rh.class.name}") if(not rh.is_a?(NANumber))
        return BLFloat.new((@value % rh.value).to_f)
    end
end

#==================== Complex ====================
# En lista
class BLList < NAVariable
    attr_accessor :type
    def initialize()
        @type = nil
        @value = []
    end

    # För utskrift av listan
    def output()
        print '['
        value.each_with_index do |val, index|
            val.output()
            print ', ' if(index + 1 < value.length)
        end
        print ']'
        return nil
    end

    def value=(value)
        evaled_value = []
        value.each do |val|
            evaled = val.eval()
            raise RuntimeError.new("Tried putting wrong type of value in BLList") if(not evaled.is_a?(@type))
            evaled_value << evaled
        end
        @value = evaled_value
        return self
    end

    # Lägger till ett värde i slutet
    def append(value)
        raise RuntimeError.new("Tried putting wrong type of value in #{self.class}") if(not value.is_a?(@type))
        @value << copy(value)
        return value
    end

    # Tar bort sista värdet och returnerar det
    def pop(value)
        return @value.pop
    end

    # Lägger till ett värde vid en specifierad platts
    def insert(index, value)
        raise RuntimeError.new("Tried indexing #{self.class} with non integer value, value type was #{index.class.name}") if(not index.is_a?(BLInteger))
        raise RuntimeError.new("Tried putting wrong type of value in #{self.class}") if(not value.is_a?(@type))
        @value.insert(index.value, copy(value))
        return value
    end

    # Tar bort ett värde vid en specifierad platts och returnerar värdet
    def remove(index)
        raise RuntimeError.new("Tried indexing #{self.class} with non integer value, value type was #{index.class.name}") if(not index.is_a?(BLInteger))
        return @value.delete(index.value)
    end

    # Hämtar en variabel på en specifik platts så variabeln kan modifieras
    def index(index)
        raise RuntimeError.new("Tried indexing #{self.class} with non integer value, value type was #{index.class.name}") if(not index.is_a?(BLInteger))
        return @value[index.value]
    end

    # returnerar hur många värden som finns i listan
    def count()
        return BLInteger.new(value.length);
    end

    def tree(base="")
        puts self.class.name
        puts base + "┠─Type: #{@type}"
        puts base + '┖─Data'
        base += '  '
        @value.each_with_index do |val, index|
            if(index + 1 < @value.length)
                print base + '┠─'
                val.tree(base + '┃ ')
            else
                print base + '┖─'
                val.tree(base + '  ')
            end
        end
    end
end

# En sträng av bokstäver
# En lätt modifierad lista som är låst till char typen och har ett speciellt print beteende
class BLString < BLList
    def initialize()
        @type = BLChar
        @value = []
    end

    def type=(trash)
        raise SyntaxError.new("Can not set datatype BLString stores, always stores BLChar")
    end

    def output()
        @value.each do |val|
            val.output
        end
        return nil
    end
end