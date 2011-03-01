require 'roc/store'
require 'roc/objects'


__END__

module ROC

  ## make this a module for inclusion instead?
  class ScalarType < Object

    def value
      self.deserialize(self.call :get)
    end

    def value=(val)
      self.call :set, self.serialize(val)
    end

    def serialize(val)
      val
    end

    def deserialize(val)
      val
    end

    def respond_to?(method_name)
      ## todo - what about :value, deserialize, etc!!
      self.value.respond_to?(method_name)
    end

    def method_missing(method_name, *args, &block)
      v = self.value
      if v.respond_to?(method_name)
        v.send(method_name, *args, &block)
      else
        super(method_name, *args, &block)        
      end
    end

  end

  class String < ScalarType

    alias :to_s :value
    alias :to_string :value

    def append(str)
      self.call :append, str
    end
    alias :<< :append
    
    def substring(first_index, last_index)
      self.call :substr, first_index, last_index
    end
    alias :substr :substring

    def slice(range_or_num, num=nil)
      if range_or_num.is_a?(Fixnum)
        if num.nil?
          substring(range_or_num, range_or_num)[0] ## to fully emulate Ruby
        else
          substring(range_or_num, range_or_num + num - 1)
        end
      elsif range_or_num.is_a?(Range)
        substring(range_or_num.first, (range_or_num.exclude_end? ? range_or_num.last - 1 : range_or_num.last))
      else
        if num.nil?
          self.value.slice(range_or_num)
        else
          self.value.slice(range_or_num, num)
        end
      end
    end
    alias :[] :slice

    ## @@ todo: implement slice!

    def serialize(val)
      val.to_s
    end

    def deserialize(val)
      val.to_s
    end

  end

  class Integer < ScalarType

    alias :to_i :value
    alias :to_integer :to_i

    def increment(by=nil)
      if by.nil?
        self.call :incr
      else
        self.call :incrby, by
      end
    end
    alias :incr :increment
    alias :incrby :increment

    def decrement(by=nil)
      if by.nil?
        self.call :decr
      else
        self.call :decrby, by
      end
    end
    alias :decr :decrement
    alias :decrby :decrement

    def serialize(val)
      val.to_s
    end

    def deserialize(val)
      val.to_i
    end      

  end

  class Float < ScalarType

    def serialize(val)
      val.to_s
    end

    def deserialize(val)
      val.to_f
    end

  end

  class Time < ScalarType

    alias :to_time :value
    
    def serialize(val)
      val.to_i.to_s + '.' + val.usec.to_s ##strait to_f loses precision
    end

    def deserialize(val)
      Kernel.const_get('Time').at(val.to_f) ##@@ must be a better way
    end

  end

  ## make this a module for inclusion instead?
  class ArrayType < Object  

    def serialize_value(val)
      val
    end

    def deserialize_value(val)
      val
    end

    ## items is overriden in each of the subclasses
    def items
      raise NotImplementedError
    end

    alias :to_a :items
    alias :to_ary :items

    def respond_to?(method_name)
      self.items.respond_to?(method_name)
    end

    def method_missing(method_name, *args, &block)
      i = self.items
      if i.respond_to?(method_name)
        i.send(method_name, *args, &block)
      else
        super(method_name, *args, &block)        
      end
    end

  end

  class List < ArrayType

    def items
      self.range(0, self.size).map{|v| self.deserialize_value(v)}
    end

    ## Redis methods: ##

    def push(val)
      self.call :rpush, self.serialize_value(val)
    end
    alias :<< :push
    alias :rpush :push

    def pop
      self.deserialize_value(self.call :rpop)
    end
    alias :rpop :pop

    def unshift(val)
      self.call :lpush, self.serialize_value(val)
    end
    alias :lpush :unshift

    def shift
      self.deserialize_value(self.call :lpop)
    end
    alias :lpop :shift

    def size
      self.call :llen
    end
    alias :llen :size
    alias :len :size
    alias :length :size

    def range(first_index, last_index)
      (self.call :lrange, first_index, last_index).map{|v| self.deserialize_value(v)}
    end
    alias :lrange :range

    ## index is not aliased, because it means something different in a Ruby Array
    def lindex(ind)
      self.deserialize_value(self.call :lindex, ind)
    end

    def slice(range_or_num, num=nil)
      if range_or_num.is_a?(Fixnum)
        if num.nil?
          lindex(range_or_num)
        else
          range(range_or_num, range_or_num + num - 1)
        end
      elsif range_or_num.is_a?(Range)
        range(range_or_num.first, (range_or_num.exclude_end? ? range_or_num.last - 1 : range_or_num.last))
      else
        if num.nil?
          self.items.slice(range_or_num)
        else
          self.items.slice(range_or_num, num)
        end
      end
    end
    alias :[] :slice
    ## @@ todo: implement slice!

    def trim(first_index, last_index)
      (self.call :ltrim, first_index, last_index).map{|v| self.deserialize_value(v)}
    end
    alias :ltrim :trim
    
    def lset(ind, val)
      self.call :lset, ind, self.serialize_value(val)
    end
    alias :[]= :lset 
    
    ## not: this returns number removed, not the value/nil -- split these @@??
    def delete(val, count=nil)
      self.call :lrem, (count.nil? ? 0 : count), val
    end
    alias :lrem :delete
    
    #blpop, brpop not implemented

    def rpoplpush(other_list=nil)
      self.deserialize_value(self.call :rpoplpush, (other_list.nil? ? self.key : other_list.key))
    end
    alias :pop_shift :rpoplpush
    
    # sort not yet implemented

  end

  class Set < ArrayType

    def add(val)
      self.call :sadd, self.serialize_value(val)
    end
    alias :sadd :add
    alias :<< :add

    def delete(val)
      self.call :srem, self.serialize_value(val)
    end
    alias :rem :delete
    alias :srem :delete
    
    def pop
      self.deserialize_value(self.call :spop)
    end
    alias :spop :pop
    
    def move_into(other_set, val)
      self.call :smove, other_set.key, self.serialize_value(val)
    end
    alias :move :move_into
    alias :smove :move_into

    def size
      self.call :scard
    end
    alias :length :size
    alias :card :size
    alias :scard :size

    def include?(val)
      self.call :sismember, self.serialize_value(val)
    end
    alias :has_member? :include?
    alias :has_value? :include?
    alias :ismember :include?
    alias :sismember :include?

    def intersect(*other_sets)
      (self.call :sinter, *other_sets.map{|s| s.key}).map{|v| self.deserialize_value(v)}
    end
    alias :inter :intersect
    alias :sinter :intersect

    def union(*other_sets)
      (self.call :sunion, *other_sets.map{|s| s.key}).map{|v| self.deserialize_value(v)}
    end
    alias :sunion :union
    
    def set_as_intersect_of(*other_sets)
      self.call :sinterstore, *other_sets.map{|s| s.key}
    end
    alias :interstore :set_as_intersect_of
    alias :sinterstore :set_as_intersect_of

    def set_as_union_of(*other_sets)
      self.call :sunionstore, *other_sets.map{|s| s.key}
    end
    alias :unionstore :set_as_union_of
    alias :sunionstore :set_as_union_of
    
    def diff(*other_sets)
      (self.call :sdiff, *other_sets.map{|s| s.key}).map{|v| self.deserialize_value(v)}
    end
    alias :sdiff :diff

    def -(other_set)
      diff(other_set)
    end

    def set_as_diff_of(*other_sets)
      self.call :sdiffstore, *other_sets.map{|s| s.key}
    end
    alias :diffstore :set_as_diff_of
    alias :sdiffstore :set_as_diff_of
    
    def items
      (self.call :smembers).map{|v| self.deserialize_value(v)}
    end
    alias :members :items
    alias :smembers :items

    def rand_item
     self.deserialize_value(self.call :srandmember)
    end
    alias :random_item :rand_item
    alias :rand_member :rand_item
    alias :random_member :rand_item
    alias :randmember :rand_item
    alias :srandmember :rand_item

    ## sort not yet implemented @@

  end

  class SortedSet < ArrayType
    
    def add(val, score)
      self.call :zadd, score, self.serialize_value(val)
    end
    alias :zadd :add

    def <<(val_and_score)
      if val_and_score.is_a?(Array)
        add(*val_and_score)
      elsif val_and_score.is_a?(Kernel.const_get('Hash')) && val_and_score.has_key?(:value) && val_and_score.has_key?(:score)
        add(val_and_score[:value], val_and_score[:score])
      else
        puts "here"
        raise ArgumentError.new('<< takes an Array or a Hash')
      end
    end

    def delete(val)
      self.call :zrem, self.serialize_value(val)
    end
    alias :rem :delete
    alias :zrem :delete

    def increment(val, by=nil)
      self.call :zincrby, (by.nil? ? 1 : by)
    end
    alias :increment_by :increment
    alias :incr_by :increment
    alias :incrby :increment
    alias :zincrby :increment

    def rank(val)
      self.call :zrank, self.serialize_value(val)
    end
    alias :zrank :rank

    def include?(val)
      !self.rank(val).nil?
    end
    alias :has_member? :include?
    alias :has_value? :include?

    def reverse_rank(val)
      self.call :zrevrank, self.serialize_value(val)
    end
    alias :revrank :reverse_rank
    alias :zrevrank :reverse_rank

    def range(first_index, last_index)
      (self.call :zrange, first_index, last_index).map{|v| self.deserialize_value(v)}
    end
    alias :zrange :range

    def slice(range_or_num, num=nil)
      if range_or_num.is_a?(Fixnum)
        if num.nil?
          range(range_or_num, range_or_num).first
        else
          range(range_or_num, range_or_num + num - 1)
        end
      elsif range_or_num.is_a?(Range)
        range(range_or_num.first, (range_or_num.exclude_end? ? range_or_num.last - 1 : range_or_num.last))
      else
        if num.nil?
          self.items.slice(range_or_num)
        else
          self.items.slice(range_or_num, num)
        end
      end
    end
    alias :[] :slice
    ## @@ todo: implement slice!

    def size
      self.call :zcard
    end
    alias :length :size
    alias :card :size
    alias :zcard :size

    ## @@use multi for this?
    def items
      self.range(0, self.size - 1)
    end

    def set_as_intersect_of(*other_sorted_sets)
      self.call :zinterstore, other_sorted_sets.map{|s| s.key}
    end
    alias :interstore :set_as_intersect_of
    alias :zinterstore :set_as_intersect_of

    def set_as_union_of(*other_sorted_sets)
      self.call :zunionstore, other_sorted_sets.map{|s| s.key}
    end
    alias :unionstore :set_as_union_of
    alias :zunionstore :set_as_union_of
    

    ## implemente pop using range and rem in a multi block

  end

  class Hash < Object

    def serialize_value(val)
      val
    end

    def deserialize_value(val)
      val
    end

    def to_hash
      self.call :hgetall
    end
    alias :hgetall :to_hash
    alias :getall :to_hash

    alias :to_h :to_hash

    def respond_to?(method_name)
      self.to_hash.respond_to?(method_name)
    end

    def method_missing(method_name, *args, &block)
      h = self.to_hash
      if h.respond_to?(method_name)
        h.send(method_name, *args, &block)
      else
        super(method_name, *args, &block)        
      end
    end

    def get(property)
      self.deserialize_value(self.call :hget, property)
    end
    alias :hget :get
    alias :[] :get

    def set(property, value)
      self.call :hset, property, self.serialize_value(value)
    end
    alias :hset :get
    alias :[]= :set

    def has_key?(property)
      self.call :hexists, property
    end
    alias :hexists :has_key?
    alias :exists :has_key?
    alias :exists? :has_key?
    
    def keys
      self.call :hkeys
    end
    alias :hkeys :keys

    def values
      (self.call :hvals).map{|v| self.deserialize_value(v)}
    end
    alias :hvals :values
    alias :vals :values

    def size
      self.call :hlen
    end
    alias :length :size
    alias :len :size
    alias :hlen :size

    def delete(property)
      self.call :hdel, property
    end
    alias :del :delete
    alias :hdel :delete

    def increment(property, by=nil)      
      self.call :hincrby, property, (by.nil? ? 1 : by.to_i)
    end
    alias :incr :increment
    alias :incrby :increment
    alias :incrementby :increment
    alias :increment_by :increment
    alias :hincrby :increment

    def decrement(property, by=nil)      
      self.call :hincrby, property, (by.nil? ? -1 : -by.to_i)
    end
    alias :decr :decrement
    alias :decrby :decrement
    alias :decrementby :decrement
    alias :decrement_by :decrement

    ## mset and mget

  end

end



### http://github.com/rcrowley/lazy_redis/blob/master/lib/lazy_redis.rb
