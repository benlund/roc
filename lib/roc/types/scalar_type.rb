require 'roc/types/method_generators'

module ROC
  module Types
    module ScalarType
      extend ROC::Types::MethodGenerators
      
      deserializing_method :get
        
      alias value get

      serializing_method :set

      alias value= set

      serializing_method :setnx

      serializing_and_deserializing_method :getset

      def setex(secs, val)
        self.set(val)
        self.expire(secs)
      end

      def clobber(data)
        self.set(data)
      end

      def inspect
        "<#{self.class} @storage=#{self.storage.inspect} @key=#{self.key.inspect} @value=#{self.value.inspect}>"
      end      

      def serialize(val)
        raise "serialize must be overriden in any class including ScalarType"
      end
      
      def deserialize(val)
        raise "deserialize must be overriden in any class including ScalarType"
      end

#       def respond_to?(method_name)
#         ## todo - what about :value, deserialize, etc!!
#         self.value.respond_to?(method_name)
#       end
      
#       def method_missing(method_name, *args, &block)
#         v = self.value
#         if v.respond_to?(method_name)
#           v.send(method_name, *args, &block)
#         else
#           super(method_name, *args, &block)        
#         end
#       end


    end
  end
end
