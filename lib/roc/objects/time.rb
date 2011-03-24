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
      if ::Time.now.respond_to?(:nsec)
        val.to_i.to_s + '.' + val.nsec.to_s ##strait to_f loses precision
      else
        val.to_i.to_s + '.' + val.usec.to_s ##strait to_f loses precision
      end
    end

    def deserialize(val)
      if val.nil?
        nil
      else
        parts = val.split('.')
        if ::Time.now.respond_to?(:nsec)
          ::Time.at(parts[0].to_i, (parts[1].to_i / 1000))
        else
          ::Time.at(parts[0].to_i, parts[1].to_i)
        end
      end
    end

  end
end
