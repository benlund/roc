require 'roc/types/method_generators'

module ROC
  module Types
    module ArrayType

      def self.included(base)
        base.send :delegate_methods, :on => [], :to => :values
      end

      ## methods that must be implemented

      def size
        raise NotImplementedError, 'size must be overriden in any class including ArrayType'
      end

      def clobber(data)
        raise NotImplementedError, 'clobber must be overriden in any class including ArrayType'
      end
      
      # note - overriden methods should always return an array, never nil
      def values
        raise NotImplementedError, 'values must be overriden in any class including ArrayType'
      end

      ## common stuff

      # can't alias - it will to find the method in subclass
      def to_array 
        self.values
      end
      def to_ary
        self.values
      end
      def to_a
        self.values
      end

      def values=(data)
        self.clobber(data)
      end

      def inspect
        "<#{self.class} @storage=#{self.storage.inspect} @key=#{self.key.inspect} @size=#{self.size}>"
      end      

      ## destructive methods that we can implement here

      def replace(val)
        self.clobber(val)
        self
      end

      def clear
        self.replace([])
      end     

      ## destructive methods that would otherwise be delegated -- override if possible (these are in addition to a ny methods ending in ! or =, which are caught by method_missing)

      def delete(val)
        raise NotImplementedError
      end

      def delete_at(ind)
        raise NotImplementedError
      end
      
      def delete_if
        raise NotImplementedError
      end

      def <<(val)
        raise NotImplementedError
      end
      
      def fill(*args)
        raise NotImplementedError
      end

      def insert(*args)
        raise NotImplementedError
      end

      def keep_if
        raise NotImplementedError
      end

      def push(*args)
        raise NotImplementedError
      end

      def pop(*args)
        raise NotImplementedError
      end

      def shift(*args)
        raise NotImplementedError
      end

      def unshift(*args)
        raise NotImplementedError
      end

    end
  end
end
