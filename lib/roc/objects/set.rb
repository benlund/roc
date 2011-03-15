require 'roc/objects/base'
require 'roc/types/array_type'

module ROC
  class Set < Base
    include ROC::Types::ArrayType
    extend ROC::Types::MethodGenerators   

    nonserializing_method :sadd
    alias add sadd
    alias << sadd

    zero_arg_method :scard

    nonserializing_method :sismember
    alias ismember sismember
    alias ismember? sismember
    alias is_member? sismember
    alias include? sismember

    zero_arg_method :smembers
    alias members smembers

    zero_arg_method :spop
    alias pop spop

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
    alias & sinter

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

    ## implement (if posible) destructive methods that would otherwise raise

    def delete(val)
      if self.srem(val)
        val
      else
        nil
      end
    end

    ## implementing ArrayType ##

    def clobber(vals)
      vals.each{|v| self << v}
    end

    alias values smembers

    alias size scard
    alias length scard

  end
end
