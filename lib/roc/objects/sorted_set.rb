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
    alias card zcard

    def zrange(start_index, stop_index, opts={})
      self.call :zrange, start_index, stop_index, opts
    end
    alias range zrange

    def zrevrange(start_index, stop_index, opts={})
      self.call :zrevrange, start_index, stop_index, opts
    end
    alias revrange zrevrange

    def zrangebyscore(min, max, opts={})
      self.call :zrangebyscore, min, max, opts
    end
    alias rangebyscore zrangebyscore

    def zrevrangebyscore(max, min, opts={})
      self.call :zrevrangebyscore, max, min, opts
    end
    alias revrangebyscore zrevrangebyscore

    def zcount (min, max)
      self.call :zcount, min, max
    end
    alias count zcount

    nonserializing_method :zrank
    alias rank zrank

    nonserializing_method :zrevrank
    alias revrank zrevrank

    nonserializing_method :zscore
    alias score zscore

    def zincrby(by, val)
      self.call :zincrby, by, val
    end
    alias incrby zincrby

    nonserializing_method :zrem
    alias rem zrem

    def zremrangebyscore(min, max)
      self.call :zremrangebyscore, min, max
    end
    alias remrangebyscore zremrangebyscore

    def zremrangebyrank(start, stop)
      self.call :zremrangebyrank, start, stop
    end
    alias remrangebyrank zremrangebyrank

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

    ## shortcut methods

    def [](range_or_num, num=nil)
      if range_or_num.is_a?(::Integer)
        if num.nil?
          self.zrange(range_or_num, range_or_num)[0]
        elsif num >= 0
          self.zrange(range_or_num, range_or_num + num - 1)
        else
          raise ArgumentError, 'second arg to [] must be a non-neg integer'
        end
      elsif range_or_num.is_a?(Range)
        self.zrange(range_or_num.first, (range_or_num.exclude_end? ? range_or_num.last - 1 : range_or_num.last))
      else
        if num.nil?
          self.values.slice(range_or_num)
        else
          self.values.slice(range_or_num, num)
        end
      end
    end
    alias slice []

    def first
      self.zrange(0, 0)[0]
    end

    def last
      self.zrange(-1, -1)[0]
    end

    def include?(val)
      !self.zrank(val).nil?
    end
    
    def index(val)
      self.zrank(val)
    end

    def reverse
      self.zrevrange(0, -1)
    end

    # helpers

    def decrby(by, val)
      self.zincrby -by, val
    end

    def increment(val, by=nil)
      self.zincrby( (by || 1), val )
    end

    def decrement(val, by=nil)
      self.zincrby( -(by || 1), val )
    end

    def to_hash
      hsh = {}
      vals_with_scores = self.zrangebyscore('-inf', '+inf', :with_scores => true)
      i = 0
      l = vals_with_scores.size
      while i < l
        hsh[vals_with_scores[i]] = vals_with_scores[i+1]
        i += 2
      end
      hsh
    end
    alias to_h to_hash

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
        raise ArgumentError, 'an Array or a Hash required'
      end
      self
    end

    def push(*objs)
      if 1 == objs.size
        self << objs[0]
      elsif objs.size > 1
        self.storage.multi do 
          objs.each do |obj|
            self << obj
          end
        end
      end
      self
    end

    ## implementing ArrayType ##

    def clobber(vals)
      self.storage.multi do 
        self.forget
        vals.each{|v| self << v}
      end
    end

    def values(opts = {})
      self.zrange(0, -1, opts)
    end

    alias size zcard
    alias length zcard

  end
end
