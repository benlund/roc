module ROC
  module Store
    module ObjectInitializers

      def init(klass, key, seed_data=nil)
        klass.new(self, key, seed_data)
      end

      def find(key)
        if klass = class_for_key(key)
          init(klass, key)
        else
          nil
        end
      end

      def class_for_key(key)
        case t = self.call(:type, key)
        when 'string'
          ROC::String
        when 'list'
          ROC::List
        when 'set'
          ROC::Set
        when 'zset'
          ROC::SortedSet
        when 'hash'
          ROC::Hash
        when 'none'
          nil
        else
          raise "unknown type: #{t}"
        end
      end
      
      def init_string(key, seed_data=nil)
        init(ROC::String, key, seed_data)
      end
      
      def init_integer(key, seed_data=nil)
        init(ROC::Integer, key, seed_data)
      end
      
      def init_float(key, seed_data=nil)
        init(ROC::Float, key, seed_data)
      end
      
      def init_time(key, seed_data=nil)
        init(ROC::Time, key, seed_data)
      end
      
      def init_list(key, seed_data=nil)
        init(ROC::List, key, seed_data)
      end
      
      def init_set(key, seed_data=nil)
        init(ROC::Set, key, seed_data)
      end
      
      def init_sorted_set(key, seed_data=nil)
        init(ROC::SortedSet, key, seed_data)
      end
      
      def init_hash(key, seed_data=nil)
        init(ROC::Hash, key, seed_data)
      end

    end
  end
end
