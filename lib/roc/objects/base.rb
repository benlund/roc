if RUBY_VERSION.match(/^1\.8/)
  require 'rubygems'
end
require 'cim_attributes'

require 'roc/types/all_types'

module ROC
  class Base
    include ROC::Types::AllTypes
    include CIMAttributes

    attr_reader :key, :options

    cim_attr_accessor :storage

    # key, [storage], [seed_data], [opts]
    def initialize(key, *args)
      @key = key

      if args.last.is_a?(Hash)
        @options = args.pop
      end

      if args.first.is_a?(ROC::Store::ROCStore)
        @storage = args.shift
      end

      if !self.storage
        raise ArgumentError, 'no class-level storage set, so must initialize with a Store'
      end

      if args.size > 1
        raise ArgumentError, 'new(key, [storage], [seed_data], [opts])'
      end

      if !(seed_data = args.pop).nil?
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
