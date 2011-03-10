require 'roc/store/object_initializers'
module ROC
  module Store
    class TransientStore
      include ObjectInitializers

      KEYSPACES = {}
      MDSPACES = {}

      attr_reader :name

      def initialize(name)
        @name = name.to_s
        TransientStore::KEYSPACES[@name] ||= {}
        TransientStore::MDSPACES[@name] ||= {}
      end

      protected

      def keyspace
        TransientStore::KEYSPACES[self.name]
      end

      def mdspace
        TransientStore::MDSPACES[self.name]
      end

      def expunge_if_expired(key)
        if (md = self.mdspace[key.to_s]) && (ea = md[:expire_at]) && (ea < ::Time.now.to_i)
          self.expunge(key)
        end
      end

      def expunge(key)
        self.keyspace.delete(key.to_s)
        self.mdspace.delete(key.to_s)
      end

      def with_type(key, type)
        md = self.mdspace[key.to_s]
        if md.nil? || (md[:type] == type)
          ret = yield
          self.mdspace[key.to_s] ||= {:type => type}
          ret
        else
          raise TypeError, "#{type} required"
        end
      end

      public

      def call(method_name, key, *args)
        send method_name, key, *args
      end

      ## start of redis methods

      # All keys

      def del(*keys)
        keys.each{|key| expunge_if_expired(key)}
        i = 0
        keys.each do |key|
          if self.exists(key)
            self.expunge(key)
            i += 1
          end
        end
        if keys.size > 1
          true
        else
          i
        end
      end

      def exists(key)
        expunge_if_expired(key)
        self.keyspace.has_key?(key.to_s)
      end

      def expire(key, secs)
        self.expireat(key, ::Time.now.to_i + secs.to_i)
      end

      def expireat(key, epoch)
        if self.exists(key)
          self.mdspace[key.to_s] ||= {}
          self.mdspace[key.to_s][:expire_at] = epoch.to_i
          true
        else
          false
        end
      end

      def keys
        raise "unimeplemented"
      end

      def move(key, db)
        raise "unimeplemented"
      end

      def persist(key)
        if self.exists(key) && (md = self.mdspace[key.to_s]) && md.has_key?(:expire_at)
          md.delete(:expire_at)
          true
        else
          false
        end
      end

      def randomkey
        raise "unimeplemented"
      end

      def rename(key, newkey)
        raise "unimeplemented"
      end

      def renamenx(key, newkey)
        raise "unimeplemented"
      end

      def sort(*args)
        raise "unimeplemented"
      end

      def ttl(key)
        val = -1
        if self.exists(key)
          if (md = self.mdspace[key.to_s]) && (ea = md[:expire_at])
            val = ea - ::Time.now.to_i
          end
        end
        val
      end

      def type(key)
        if md = self.mdspace[key.to_s]
          md[:type]
        else
          'none'
        end
      end

      # Strings

      def get(key)
        with_type(key, 'string') do
          expunge_if_expired(key)  
          self.keyspace[key.to_s]
        end
      end

      def set(key, val)
        with_type(key, 'string') do
          expunge_if_expired(key)
          self.keyspace[key.to_s] = val.to_s
          self.persist(key)
          true
        end
      end

      def getset(key, val)
        current_val = self.get(key)
        self.set(key, val)
        current_val
      end

      def mget(*keys)
        keys.map{|k| self.get(k)}
      end

      def mset(*pairs)
        i=0
        while i < pairs.size
          self.set(pairs[i], pairs[i+1])
          i+=2
        end
        true
      end

      def setnx(key, val)
        if self.exists(key)
          false
        else
          self.set(key, val)
          true
        end
      end

      def msetnx(*pairs)
        i=0
        any_exist = false
        while i < pairs.size
          if self.exists(pairs[i])
            any_exist = true
            break
          end
        end
        if !any_exist
          i=0
          while i < pairs.size
            self.set(pairs[i], pairs[i+1])
            i+=2
          end
          true
        else
          false
        end
      end

      def append(key, val)
        if self.exists(key)
          with_type(key, 'string') do
            self.keyspace[key.to_s] << val.to_s
          end
        else
          self.set(key, val)
        end
        self.strlen(key)
      end

      def getbit(key, index)
        raise ArgumentError, 'setbit takes a non-negative index' unless index > 0

        bitstring = self.get(key).to_s.unpack('B*')[0]
        if index < bitstring.length
          bitstring[index].to_i
        else
          0
        end
      end

      def setbit(key, index, value)
        raise ArgumentError, 'setbit takes a non-negative index' unless index > 0
        raise ArgumentError, 'setbit takes a 1 or 0 for the value' unless((0 == value) || (1 == value))

        bitstring = self.get(key).to_s.unpack('B*')[0]
        current_val = 0
        if index < bitstring.length         
          current_val = bitstring[index].to_i
          bitstring[index] = value.to_s
        else
          bitstring << ('0' * (index - bitstring.length))
          bitstring << value
        end
        self.set(key, [bitstring].pack('B*'))
        current_val
      end


      def getrange(key, first_index, last_index)
        if self.exists(key)
          with_type(key, 'string') do
            self.keyspace[key.to_s][first_index..last_index]
          end
        else
          ''
        end
      end

      def setrange(key, start_index, val)
        with_type(key, 'string') do
          expunge_if_expired(key)
          if start_index < 1
            raise "index out of range: #{start_index}"          
          end
          length = self.strlen(key)
          padding_length = start_index - length
          if padding_length > 0
            self.keyspace[key.to_s][length, padding_length + val.length] = ("\u0000" * padding_length) + val
          else
            self.keyspace[key.to_s][start_index, val.length] = val
          end
          self.strlen(key)
        end
      end

      def strlen(key)
        self.get(key).to_s.bytesize
      end

      def incr(key)
        self.incrby(key, 1)
      end

      def incrby(key, by)
        val = self.get(key)
        new_val = val.to_i + by
        self.set(key, new_val.to_s)
        new_val
      end

      def decr(key)
        self.incrby(key, -1)
      end

      def decrby(key, by)
        self.incrby(key, -by)
      end

      ## end of redis methods

      def method_missing(method_name, key, *args)
        puts "unimplmented: #{method_name}, #{key}, #{args}"
      end

      def inspect
        "<#{self.class} @name=#{self.name.inspect}>"
      end

    end
  end
end
