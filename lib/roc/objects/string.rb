require 'roc/objects/base'
require 'roc/types/scalar_type'

module ROC
  class String < Base
    include ROC::Types::ScalarType
    extend ROC::Types::MethodGenerators

    alias to_string value
    alias to_s value

    delegate_methods :on => '', :to => :value

    nonserializing_method :append
    alias << append

    def getrange(first_index, last_index)
      self.call :getrange, first_index, last_index
    end
    alias substr getrange
    alias substring getrange

    nonserializing_method :getbit

    def setbit(index, val)
      self.call :setbit, index, val
    end

    def setrange(start_index, val)
      self.call :setrange, start_index, val
    end
    alias splice setrange

    zero_arg_method :strlen
    alias length strlen
    alias size strlen

    ## implementing scalar type required methods ##

    def serialize(val)
      val
    end
    
    def deserialize(val)
      val
    end

  end
end
