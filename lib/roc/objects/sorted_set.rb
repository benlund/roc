require 'roc/objects/base'
module ROC
  class SortedSet < Base
    include ROC::Types::ArrayType
    extend ROC::Types::MethodGenerators   

    def zadd(score, val)
      self.call :zadd, score, val
    end
    alias add zadd

    zero_arg_method :zcard

    def zrange(start_index, stop_index, opts={})
      self.call :zrange, start_index, stop_index, opts
    end

    nonserializing_method :zrem
    alias rem zrem

    def zinterstore(*other_sorted_sets)
      opts = if other_sorted_sets.last.is_a?(::Hash)
               other_sorted_sets.pop
             else
               {}
             end
        
      self.call :zinterstore, [*other_sorted_sets].map{|s| s.key}, opts
    end
    alias interstore zinterstore
    alias inter_store zinterstore
    alias set_as_intersect_of zinterstore

    def zunionstore(*other_sorted_sets)
      opts = if other_sorted_sets.last.is_a?(::Hash)
               other_sorted_sets.pop
             else
               {}
             end
      self.call :zunionstore, [*other_sorted_sets].map{|s| s.key}, opts
    end
    alias unionstore zunionstore
    alias union_store zunionstore
    alias set_as_union_of zunionstore

    ## include?

    ## implement (if posible) destructive methods that would otherwise raise

    def delete(val)
      if self.zrem(val)
        val
      else
        nil
      end
    end

    def <<(val_and_score)
      if val_and_score.is_a?(Array)
        self.zadd *val_and_score
      elsif val_and_score.is_a?(::Hash) && val_and_score.has_key?(:value) && val_and_score.has_key?(:score)
        self.zadd(val_and_score[:score], val_and_score[:value])
      else
        raise ArgumentError, '<< takes an Array or a Hash'
      end
    end

    ## implementing ArrayType ##

    def clobber(vals)
      vals.each{|v| self << v}
    end

    def values(opts = {})
      self.zrange(0, -1, opts)
    end

    alias size zcard
    alias length zcard

  end
end
