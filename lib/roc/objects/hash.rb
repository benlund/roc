require 'roc/objects/base'
module ROC
  class Hash < Base
    extend ROC::Types::MethodGenerators   

    delegate_methods :on => {}, :to => :to_hash

    nonserializing_method :hdel

    nonserializing_method :hexists
    alias exists hexists
    alias exists? hexists
    alias key? hexists
    alias has_key? hexists
    alias member? hexists
    alias include? hexists

    nonserializing_method :hget
    alias get hget

    zero_arg_method :hgetall
    alias getall hgetall

    def hincrby(field, increment)
      self.call :hincrby, field, increment
    end
    alias incrby hget

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

    def hsetnx(field, val)
      self.call :hsetnx, field, val
    end
    alias setnx hsetnx

    zero_arg_method :hvals
    alias vals hvals
    alias values hvals

    # shortcuts/helpers

    def [](*args)
      if 1 == args.size
        self.hget(args[0])
      else
        self.hmget(*args)
      end
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

    ## destructive

    def delete(field)
      val = self.hget(field)
      self.hdel(field)
      val
    end

    ## implementing for delegate

    alias to_hash getall

  end
end
