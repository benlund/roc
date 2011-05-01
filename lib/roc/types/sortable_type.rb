module ROC
  module Types
    module SortableType

#      c.value :by
#      c.splat :limit
#      c.multi :get
#      c.words :order
#      c.value :store

      def sort(opts={})
        raise ":by not yet supported" if opts.has_key?(:by)
        raise ":get not yet supported" if opts.has_key?(:by)

        store = opts[:store]
        if store.is_a?(ROC::List)
          store = store.key
        elsif !store.nil? && !store.is_a?(::String)
          raise "unsupported :store value"
        end

        self.call :sort, {:store => store, :limit => opts[:limit], :order => opts[:order]}
      end

      def sort!(opts={})
        raise ":store is self in sort!" if opts.has_key?(:store)
        self.sort({:store => self.key}.merge(opts.dup))
      end

    end
  end
end
