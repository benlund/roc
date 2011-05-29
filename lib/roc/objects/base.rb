require 'roc/types/all_types'

module ROC
  class Base
    include ROC::Types::AllTypes

    attr_reader :storage, :key, :options

    def initialize(storage, key, *args)
      @storage = storage
      @key = key

      if args.last.is_a?(Hash)
        @options = args.pop
      end

      if args.size > 1
        raise ArgumentError, 'new(storage, key, [seed_data], [opts])'
      end

      if !(seed_data = args[0]).nil?
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
          !['!', '='].include?(method_name.to_s[method_name.to_s.length - 1]) # we won't delegate modifying methods
        self.send(self.class.const_get('DELEGATE_OPTIONS')[:to]).send(method_name, *args, &block)
      else
        super(method_name, *args, &block)        
      end
    end

    protected

    def call(remote_method_name, *args)
      self.storage.call(remote_method_name, self.key, *args)
    end

  end
end
