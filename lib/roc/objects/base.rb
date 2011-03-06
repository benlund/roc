require 'roc/types/all_types'

module ROC
  class Base
    include ROC::Types::AllTypes

    attr_reader :store, :key

    def initialize(store, key, seed_data=nil)
      @store = store
      @key = key
      if !seed_data.nil?
        seed(seed_data)
      end
    end
 
    def seed(data)
      if self.exists?
        raise "#{self.key} already exists -- can't seed it"
      else
        self.clobber(data)
      end
    end

    def clobber(data)
      raise "clobber must be overriden in subclasses"
    end
     
    protected

    def call(remote_method_name, *args)
      self.store.call(remote_method_name, self.key, *args)
    end

  end
end
