require 'roc/objects/base'
require 'roc/types/scalar_type'

module ROC
  class String < Base
    include ROC::Types::ScalarType
    extend ROC::Types::MethodGenerators

    delegate_methods :on => '', :to => :value

    attr_reader :encoding

    def to_string
      self.value.to_s
    end
    alias to_s to_string

    ## redis methods ##

    nonserializing_method :append
    alias << append
    alias concat append

    def getrange(first_index, last_index)
      self.call :getrange, first_index, last_index
    end
    alias substr getrange
    alias substring getrange

    nonserializing_method :getbit

    def setbit(index, val)
      self.call :setbit, index, val
    end

    def setrange(start_index, val)
      self.call :setrange, start_index, val
    end
    alias splice setrange

    zero_arg_method :strlen
    alias bytesize strlen

    ## shortcut methods

    def getbyte(ind)
      val = self.getrange(ind, ind)
      if val.nil? || ('' == val)
        nil
      else
        val.bytes.to_a[0]
      end
    end

    def setbyte(ind, int)
      self.setrange(ind, int.chr)
      int
    end

    def empty?
      0 == self.strlen
    end

    def chr
      self.getrange(0, 0)
    end

    ## implement (if posible) destructive methods that would otherwise raise

    def replace(val)
      self.set(val)
      val
    end

    def clear
      self.replace('')
    end

    def force_encoding(enc)
      @encoding = enc
    end


    ## raise destructive methods if not implemted

    def insert(ind, val)
      raise NotImplementedError
    end

    ## implementing scalar type required methods ##

    def serialize(val)
      ## use the encoding of the first val were sent unless expicitly set
      if @encoding.nil?
        @encoding = if val.respond_to?(:encoding)
                          val.encoding
                        else
                          'US-ASCII'
                        end
      end
      if val.respond_to?(:encode)
        val.encode(@encoding)
      else
        val
      end
    end
    
    def deserialize(val)
      if @encoding.nil? || !val.respond_to?(:force_encoding)
        val
      else
        val.force_encoding(@encoding)
      end
    end

  end
end
