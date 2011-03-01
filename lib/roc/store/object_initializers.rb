module ROC
  module Store
    module ObjectInitializers

      def init(klass, key)
        klass.new(self, key)
      end
      
      def init_string(key)
        init(class_for('String'), key)
      end
      
      def init_integer(key)
        init(class_for('Integer'), key)
      end
      
      def init_float(key)
        init(class_for('Float'), key)
      end
      
      def init_time(key)
        init(class_for('Time'), key)
      end
      
      def init_list(key)
        init(class_for('List'), key)
      end
      
      def init_set(key)
        init(class_for('Set'), key)
      end
      
      def init_sorted_set(key)
        init(class_for('SortedSet'), key)
      end
      
      def init_hash(key)
        init(class_for('Hash'), key)
      end

      def class_for(object_type)
        ROC.const_get("#{self.class::STORAGE_TYPE_PREFIX}#{object_type}")
      end

    end
  end
end
