module ROC
  module Types
    module MethodGenerators

      def serializing_method(method_name)
        self.send :define_method, method_name do |val|
          self.call method_name, self.serialize(val)        
        end
      end

      def deserializing_method(method_name)
        self.send :define_method, method_name do
          self.deserialize(self.call method_name)
        end
      end

      def serializing_and_deserializing_method(method_name)
        self.send :define_method, method_name do |val|
          self.deserialize(self.call method_name, self.serialize(val))
        end
      end

      def zero_arg_method(method_name)
        self.send :define_method, method_name do
          self.call method_name
        end
      end

      def nonserializing_method(method_name)
        self.send :define_method, method_name do |val|
          self.call method_name, val
        end
      end

    end
  end
end

