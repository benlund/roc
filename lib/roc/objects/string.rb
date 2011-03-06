require 'roc/objects/base'
require 'roc/types/scalar_type'

module ROC
  class String < Base
    include ROC::Types::ScalarType

    def append(val)
      self.call :append, val
    end

    alias << append

    def getrange(first_index, last_index)
      self.call :getrange, first_index, last_index
    end

    alias substr getrange

    alias substring getrange

    def setrange(start_index, val)
      self.call :setrange, start_index, val
    end

    alias splice setrange

    ## impl scalar type

    def serialize(val)
      val
    end
    
    def deserialize(val)
      val
    end

  end
end
