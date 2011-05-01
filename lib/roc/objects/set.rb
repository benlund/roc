require 'roc/objects/base'
require 'roc/types/array_type'
require 'roc/types/sortable_type'

module ROC
  class Set < Base
    include ROC::Types::ArrayType
    include ROC::Types::SortableType
    extend ROC::Types::MethodGenerators   

    nonserializing_method :sadd
    alias add sadd

    zero_arg_method :scard
    alias card scard

    nonserializing_method :sismember
    alias ismember sismember
    alias ismember? sismember
    alias is_member? sismember
    alias include? sismember

    zero_arg_method :smembers
    alias members smembers

    zero_arg_method :spop

    zero_arg_method :srandmember
    alias randmmember srandmember
    alias rand_member srandmember

    nonserializing_method :srem
    alias rem srem

    def smove(other_set, val)
      self.call :smove, other_set.key, val
    end
    alias move smove
    alias move_into smove

    def sinter(*other_sets)
      self.call :sinter, *other_sets.map{|s| s.key}
    end
    alias inter sinter
    alias intersect sinter
    alias :& :sinter ## to make rdoc parser happy

    def sunion(*other_sets)
      self.call :sunion, *other_sets.map{|s| s.key}
    end
    alias union sunion
    alias | sunion    
    
    def sdiff(*other_sets)
      self.call :sdiff, *other_sets.map{|s| s.key}
    end
    alias diff sdiff
    alias - sdiff

    def sinterstore(*other_sets)
      self.call :sinterstore, *other_sets.map{|s| s.key}
    end
    alias interstore sinterstore
    alias inter_store sinterstore
    alias set_as_intersect_of sinterstore

    def sunionstore(*other_sets)
      self.call :sunionstore, *other_sets.map{|s| s.key}
    end
    alias unionstore sunionstore
    alias union_store sunionstore
    alias set_as_union_of sunionstore
    
    def sdiffstore(*other_sets)
      self.call :sdiffstore, *other_sets.map{|s| s.key}
    end
    alias diffstore sdiffstore
    alias diff_store sdiffstore
    alias set_as_diff_of sdiffstore

    ## helpers

    def to_hash
      hsh = {}
      self.smembers.each do |val|
        hsh[val] = true
      end
      hsh
    end
    alias to_h to_hash

    ## implement (if posible) destructive methods that would otherwise raise

    def delete(val)
      if self.srem(val)
        val
      else
        nil
      end
    end

    def push(*objs)
      if 1 == objs.size
        self.sadd(objs[0])
      elsif objs.size > 1
        self.storage.multi do 
          objs.each do |obj|
            self.sadd(obj)
          end
        end
      end
      self
    end

    def <<(obj)
      self.push(obj)
    end

    def pop(*args)
      if 0 == args.size
        self.spop
      elsif 1 == args.size
        (self.storage.multi do
          args[0].times do 
            self.spop
          end
        end).reverse
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
      end      
    end
      
    ## implementing ArrayType ##

    def clobber(vals)
      self.storage.multi do 
        self.forget
        vals.each{|v| self << v}
      end
    end

    alias values smembers

    alias size scard
    alias length scard

  end
end
