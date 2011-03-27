require 'roc/objects/base'
module ROC
  class Hash < Base
    extend ROC::Types::MethodGenerators   

    delegate_methods :on => {}, :to => :to_hash

    nonserializing_method :hdel

    nonserializing_method :hexists
    alias key? hexists
    alias has_key? hexists
    alias member? hexists
    alias include? hexists

    nonserializing_method :hget
    alias get hget
    alias [] hget

    zero_arg_method :hgetall
    alias getall hgetall

    def hincrby(field, increment)
      self.call :hincrby, field, increment
    end
    alias incrby hincrby

    zero_arg_method :hkeys
    alias keys hkeys

    zero_arg_method :hlen
    alias len hlen
    alias length hlen
    alias size hlen

    def hmget(*fields)
      self.call :hmget, *fields
    end
    alias mget hmget

    def hmset(*pairs)
      self.call :hmset, *pairs
    end
    alias mset hmset
    
    def hset(field, val)
      self.call :hset, field, val
    end
    alias set hset
    alias []= hset
    alias store hset

    def hsetnx(field, val)
      self.call :hsetnx, field, val
    end
    alias setnx hsetnx

    zero_arg_method :hvals
    alias vals hvals
    alias values hvals

    # shortcuts/helpers

    alias values_at hmget

    def has_value?(val)
      self.values.include?(val)
    end
    alias value? has_value?

    def empty?
      0 == self.hlen
    end

    def decrby(field, by)
      self.hincrby field, -by
    end

    def increment(field, by=nil)
      self.hincrby field, (by || 1)
    end

    def decrement(field, by=nil)
      self.hincrby field, -(by || 1)
    end

    ## implement (if posible) destructive methods that would otherwise raise

    def merge!(hsh)
      raise ArgumentError, 'block version not supported' if block_given?
      self.hmset(*hsh.to_a.flatten)
    end
    alias update merge!

    def delete(field)
      val = self.hget(field)
      self.hdel(field)
      val
    end

    def delete_if
      raise NotImplementedError
    end

    def replace(hsh)
      raise NotImplementedError
    end

    def shift
      raise NotImplementedError
    end

    ## implementing for delegate

    alias to_hash getall

    def clobber(data)
      self.merge!(data)
    end

  end
end
