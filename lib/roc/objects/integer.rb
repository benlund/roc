require 'roc/objects/base'
module ROC
  class Integer < Base
    include ROC::Types::ScalarType

    delegate_methods :on => 0, :to => :value

    def to_integer
      self.value.to_i
    end
    alias to_int to_integer
    alias to_i to_integer

    ## implemeting redis methods ##

    def increment(by=nil)
      if by.nil?
        self.call :incr
      else
        self.call :incrby, by
      end
    end
    alias incr increment
    alias incrby increment

    def decrement(by=nil)
      if by.nil?
        self.call :decr
      else
        self.call :decrby, by
      end
    end
    alias decr decrement
    alias decrby decrement

    ## implementing scalar type required methods ##

    def serialize(val)
      val.to_s
    end
    
    def deserialize(val)
      if val.nil?
        nil
      else
        val.to_i
      end
    end

  end
end
