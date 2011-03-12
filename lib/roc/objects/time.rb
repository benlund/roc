require 'roc/objects/base'
module ROC
  class Time < Base
    include ROC::Types::ScalarType

    delegate_methods :on => ::Time.now, :to => :value

    def to_time
      v = self.value
      if v.nil?
        ::Time.at(0)
      else
        v
      end
    end

    ## implementing scalar type required methods ##

    def serialize(val)
      val.to_i.to_s + '.' + val.nsec.to_s ##strait to_f loses precision
    end

    def deserialize(val)
      if val.nil?
        nil
      else
        parts = val.split('.')
        ::Time.at(parts[0].to_i, (parts[1].to_i / 1000))
      end
    end

  end
end
