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

    def self.delegate_methods(options)
      raise ":on and :to required to delegate methods" unless options.has_key?(:on) && options.has_key?(:to)
      self.const_set('DELEGATE_OPTIONS', options)
    end

    def respond_to?(method_name)
      self.methods.include?(method_name) || (self.class.const_get('DELEGATE_OPTIONS') && self.class.const_get('DELEGATE_OPTIONS')[:on].respond_to?(method_name))
    end

    def method_missing(method_name, *args, &block)
      if self.class.const_get('DELEGATE_OPTIONS') && 
          (delegate_type = self.class.const_get('DELEGATE_OPTIONS')[:on]) && 
          delegate_type.respond_to?(method_name) &&
          (method_name.to_s[method_name.to_s.length - 1] != '!') # we won't delegate modifying methods
        self.send(self.class.const_get('DELEGATE_OPTIONS')[:to]).send(method_name, *args, &block)
      else
        super(method_name, *args, &block)        
      end
    end



    protected

    def call(remote_method_name, *args)
      self.store.call(remote_method_name, self.key, *args)
    end

  end
end
