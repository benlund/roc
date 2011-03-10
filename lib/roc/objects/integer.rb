require 'roc/objects/base'
module ROC
  class Integer < Base
    include ROC::Types::ScalarType

    alias to_integer value
    alias to_int value
    alias to_i value

    delegate_methods :on => 0, :to => :value

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
