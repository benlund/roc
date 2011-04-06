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

    nonserializing_method :rpushx
    alias pushx rpushx

    nonserializing_method :lpush

    nonserializing_method :lpushx
    alias unshiftx lpushx

    zero_arg_method :rpop

    zero_arg_method :lpop

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

    def linsert_before(pivot, value)
      self.linsert('before', pivot, value)
    end
    alias insert_before linsert_before

    def linsert_after(pivot, value)
      self.linsert('after', pivot, value)
    end
    alias insert_after linsert_after

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

    ## implement (if posible) destructive methods that would otherwise raise

    def delete(val)
      count = self.lrem(0, val)
      if count > 0
        val
      else
        nil
      end
    end

    def push(*objs)
      if 1 == objs.size
        self.rpush(objs[0])
      elsif objs.size > 1
        self.storage.multi do 
          objs.each do |obj|
            self.rpush(obj)
          end
        end
      end
      self
    end

    def <<(obj)
      self.push(obj)
    end

    def unshift(*objs)
      if 1 == objs.size
        self.lpush(objs[0])
      elsif objs.size > 1
        self.storage.multi do 
          objs.reverse.each do |obj|
            self.lpush(obj)
          end
        end
      end
      self
    end

    def pop(*args)
      if 0 == args.size
        self.rpop
      elsif 1 == args.size
        (self.storage.multi do
          args[0].times do 
            self.rpop
          end
        end).reverse
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
      end      
    end

    def shift(*args)
      if 0 == args.size
        self.lpop
      elsif 1 == args.size
        (self.storage.multi do
          args[0].times do 
            self.lpop
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

    def values
      self.lrange(0, -1)
    end

    alias size llen
    alias length llen

  end
end
