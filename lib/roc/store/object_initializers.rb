module ROC
  module Store
    module ObjectInitializers

      def init(klass, key)
        klass.new(self, key)
      end
      
      def init_string(key)
        init(ROC::String, key)
      end
      
      def init_integer(key)
        init(ROC::Integer, key)
      end
      
      def init_float(key)
        init(ROC::Float, key)
      end
      
      def init_time(key)
        init(ROC::Time, key)
      end
      
      def init_list(key)
        init(ROC::List, key)
      end
      
      def init_set(key)
        init(ROC::Set, key)
      end
      
      def init_sorted_set(key)
        init(ROC::SortedSet, key)
      end
      
      def init_hash(key)
        init(ROC::Hash, key)
      end

    end
  end
end
