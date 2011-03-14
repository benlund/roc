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
        raise "unimplemented"
      end

      def move(key, db)
        raise "unimplemented"
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
        raise "unimplemented"
      end

      def rename(key, newkey)
        raise "unimplemented"
      end

      def renamenx(key, newkey)
        raise "unimplemented"
      end

      def sort(*args)
        raise "unimplemented"
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
        raise "value (#{by}) is not an integer" unless by.is_a?(::Integer)
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

      # Lists

      def lrange(key, start_index, stop_index)
        with_type(key, 'list') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil? || (start_index >= val.size) || ( (start_index < 0) && (stop_index < start_index) )
            []
          else
            val[start_index..stop_index]
          end
        end
      end

      def llen(key)
        with_type(key, 'list') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil?
            0
          else
            val.size
          end
        end
      end

      def rpush(key, val)
        with_type(key, 'list') do
          if !self.exists(key)
            self.keyspace[key.to_s] = []
          end
          self.keyspace[key.to_s] << val
          self.keyspace[key.to_s].size
        end
      end

      def rpushx(key, val)
        if self.exists(key)
          self.rpush(key, val)
        else
          0
        end
      end

      def lpush(key, val)
        with_type(key, 'list') do
          if !self.exists(key)
            self.keyspace[key.to_s] = []
          end
          self.keyspace[key.to_s].unshift( val )
          self.keyspace[key.to_s].size
        end
      end

      def lpushx(key, val)
        if self.exists(key)
          self.lpush(key, val)
        else
          0
        end
      end

      def rpop(key)
        with_type(key, 'list') do          
          if !self.exists(key)
            nil
          else
            val = self.keyspace[key.to_s].pop  
            if 0 == self.llen(key)
              self.del(key)
            end
            val
          end
        end
      end

      def lpop(key)
        with_type(key, 'list') do          
          if !self.exists(key)
            nil
          else
            val = self.keyspace[key.to_s].shift
            if 0 == self.llen(key)
              self.del(key)
            end
            val
          end
        end
      end

      def lindex(key, ind)
        with_type(key, 'list') do          
          if !self.exists(key)
            nil
          else
            self.keyspace[key.to_s][ind]
          end
        end
      end

      def lset(key, ind, val)
        with_type(key, 'list') do
          expunge_if_expired(key)  
          arr = self.keyspace[key.to_s]
          if arr.nil?
            raise ArgumentError, "No such key: #{key}"
          elsif ((ind < 0) && (ind < -arr.size)) || (ind >= arr.size)
            raise ArgumentError, "index out of range: #{ind}"
          else
            self.keyspace[key.to_s][ind] = val
          end
        end
      end

      def lrem(key, count, val)
        with_type(key, 'list') do
          if self.exists(key)
            iterator = self.keyspace[key.to_s]
            limit = iterator.size
            reverse = false
            if count > 0
              limit = count
            elsif count < 0
              limit = count.abs
              iterator = iterator.reverse
              reverse = true
            end
            indexes_to_del = []
            iterator.each_with_index do |test, i|
              if test == val
                if reverse
                  indexes_to_del.unshift iterator.size - (i + 1)
                else
                  indexes_to_del << i
                end
              end
              if indexes_to_del.size == limit
                break
              end
            end
            correction = 0
            indexes_to_del.each do |i| 
              self.keyspace[key.to_s].delete_at(i - correction)
              correction += 1
            end
            indexes_to_del.size
          else
            0
          end
        end          
      end

      def ltrim(key, start_index, stop_index)
        arr = self.lrange(key, start_index, stop_index)
        if 0 == arr.size
          self.del(key)
        else
          self.keyspace[key.to_s] = arr
        end
        true
      end

      def rpoplpush(source_key, dest_key)
        if self.exists(source_key)
          val = self.rpop(source_key)
          self.lpush(dest_key, val)
          val
        else
          nil
        end
          
      end

      def linsert(key, where, pivot, val)
        if !['before', 'after'].include?(where.downcase)
          raise ArgumentError "BEFORE or AFTER please"
        else
          if self.exists(key)
            ind = self.keyspace[key.to_s].index(pivot)
            if ind
              if 'after' == where
                ind +=1
              end
              self.keyspace[key.to_s].insert(ind, val)
              self.keyspace[key.to_s].size
            else
              -1
            end
          else
            0
          end
        end
      end

      def blpop
        raise "blocking methods not implemented"
      end

      def brpop
        raise "blocking methods not implemented"
      end

      def brpoplpush
        raise "blocking methods not implemented"
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
