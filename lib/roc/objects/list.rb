require 'roc/objects/base'
require 'roc/types/array_type'

module ROC
  class List < Base
    include ROC::Types::ArrayType
    extend ROC::Types::MethodGenerators   

    def lrange(start_index, stop_index)
      self.call :lrange, start_index, stop_index
    end
    alias range lrange

    zero_arg_method :llen

    nonserializing_method :rpush
    alias << rpush
    alias push rpush

    nonserializing_method :rpushx

    nonserializing_method :lpush
    alias unshift lpush

    nonserializing_method :lpushx

    zero_arg_method :rpop
    alias pop rpop

    zero_arg_method :lpop
    alias shift lpop

    def lset(index, val)
      self.call :lset, index, val
    end
    alias set lset
    
    nonserializing_method :lindex
    alias index lindex

    def lrem(count, val)
      self.call :lrem, count, val
    end
    alias rem lrem

    def ltrim(start_index, stop_index)
      self.call :ltrim, start_index, stop_index
    end
    alias trim ltrim

    def rpoplpush(other_list=self)
      self.call :rpoplpush, other_list.key
    end

    def linsert(where, pivot, value)
      self.call :linsert, where, pivot, value
    end
    alias insert linsert

    def insert_before(pivot, value)
      self.insert('before', pivot, value)
    end

    def insert_after(pivot, value)
      self.insert('after', pivot, value)
    end

    ## shortcut methods

    def [](range_or_num, num=nil)
      if range_or_num.is_a?(::Integer)
        if num.nil?
          self.lindex(range_or_num)
        elsif num >= 0
          self.lrange(range_or_num, range_or_num + num - 1)
        else
          raise ArgumentError, 'second arg to [] must be a non-neg integer'
        end
      elsif range_or_num.is_a?(Range)
        self.lrange(range_or_num.first, (range_or_num.exclude_end? ? range_or_num.last - 1 : range_or_num.last))
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
      self.lindex(0)
    end

    def last
      self.lindex(-1)
    end

    def []=(*args)
      case args.size
      when 1
        raise ArgumentError, 'index required'
      when 2
        if args[0].is_a?(::Integer)
          self.lset(*args)
        else
          raise ArgumentError, 'range assignment not supported in []='
        end
      when 3
        raise ArgumentError, 'multiple index assignment not supported in []='
      else
        raise ArgumentError, 'wrong number of args'
      end
    end

    ## implement (if posible) destructive methods that would otherwise be raise

    def delete(val)
      count = self.lrem(0, val)
      if count > 0
        val
      else
        nil
      end
    end

    ## implementing ArrayType ##

    def clobber(vals)
      vals.each{|v| self << v}
    end

    def values
      self.lrange(0, -1)
    end

    alias size llen
    alias length llen

  end
end
