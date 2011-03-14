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

    ## implementing ArrayType ##

    def values
      self.lrange(0, -1)
    end

    alias size llen
    alias length llen

  end
end
