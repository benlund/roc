require 'roc/types/method_generators'

module ROC
  module Types
    module ArrayType

      def self.included(base)
        base.send :delegate_methods, :on => [], :to => :values
      end
      
      # note - overriden methods should always return an array, never nil
      def values
        raise NotImplementedError, 'values must be overriden in any class including ArrayType'
      end
      # can't alias - it will to find the method in subclass
      def to_array 
        self.values
      end
      def to_a
        self.values
      end

      def values=(data)
        self.clobber(data)
      end

      def size
        raise NotImplementedError, 'size must be overriden in any class including ArrayType'
      end

      def clobber(data)
        raise NotImplementedError, 'clobber must be overriden in any class including ArrayType'
      end

      def inspect
        "<#{self.class} @store=#{self.store.inspect} @key=#{self.key.inspect} @size=#{self.size}>"
      end      

    end
  end
end
