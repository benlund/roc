module ROC
  class Base

    attr_reader :store, :key

    def initialize(store, key, seed_data=nil)
      @store = store
      @key = key
      if !seed_data.nil?
        seed(seed_data)
      end
    end
       
    def exists?
      self.call :exists
    end
 
    def forget
      self.call :del
    end

    def inspect
      "<#{self.class} @store=#{self.store.inspect} @key=#{self.key.inspect}>"
    end
    
    protected

    def call(remote_method_name, *args)
      self.store.call(remote_method_name, self.key, *args)
    end

  end
end
