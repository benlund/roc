require 'roc/objects/base'
module ROC
  class Float < Base
    include ROC::Types::ScalarType

    delegate_methods :on => 0.0, :to => :value

    def to_float
      self.value.to_f
    end
    alias to_f to_float

    ## implementing scalar type required methods ##

    def serialize(val)
      val.to_s
    end
    
    def deserialize(val)
      if val.nil?
        nil
      else
        val.to_f
      end
    end

  end
end
