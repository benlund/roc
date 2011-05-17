require 'roc/store/object_initializers'
module ROC
  module Store
    class TransientStore
      include ObjectInitializers

      KEYSPACES = {}
      MDSPACES = {}

      attr_reader :name

      def initialize(name=nil)
        if name.nil?
          @keyspace = {}
          @mdspace = {}
        else
          @name = name.to_s
          TransientStore::KEYSPACES[@name] ||= {}
          TransientStore::MDSPACES[@name] ||= {}
        end
      end

      def shared?
        !@name.nil?
      end

      protected

      def keyspace
        @keyspace || TransientStore::KEYSPACES[self.name]
      end

      def mdspace
        @mdspace || TransientStore::MDSPACES[self.name]
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
          if self.keyspace[key.to_s]
            self.mdspace[key.to_s] ||= {:type => type}
          end
          ret
        else
          raise TypeError, "#{type} required"
        end
      end

      public

      def call(method_name, *args)
        if @multi_mode
          @multi_calls << [method_name, *args]
          'QUEUED'
        else
          self.send method_name, *args
        end
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

      def keys(pattern='*')
        if '*' == pattern
          self.keyspace.keys
        else
          raise "patterns not implemented yet"
        end
      end

      def move(key, db)
        raise NotImplementedError
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
        ks = self.keys
        ks[Kernel.rand(ks.size)]
      end

      def rename(key, newkey)
        if key.to_s == newkey.to_s
          raise ArgumentError, "keys are the same"
        elsif self.exists(key)
          self.keyspace[newkey.to_s] = self.keyspace.delete(key.to_s)
          true
        else
          raise ArgumentError, "no such key: #{key}"
        end
      end

      def renamenx(key, newkey)
        if key.to_s == newkey.to_s
          raise ArgumentError, "keys are the same"
        elsif self.exists(key)
          if self.exists(newkey)
            false
          else
            self.keyspace[newkey.to_s] = self.keyspace.delete(key.to_s)
            true
          end
        else
          raise ArgumentError, "no such key: #{key}"
        end
      end

      def sort(key, opts={})
        raise ":by not yet supported" if opts.has_key?(:by)
        raise ":get not yet supported" if opts.has_key?(:by)

        limit = opts[:limit]
        order = (opts[:order] || '').split(' ')
        store = opts[:store]
        
        md = self.mdspace[key.to_s]

        vals = if md.nil?
                 []
               elsif 'list' == md[:type]
                 self.lrange(key, 0, -1)
               elsif 'set' == md[:type]
                 self.smembers(key)
               elsif 'zset' == md[:type]
                 self.zrange(key, 0, -1)
               else
                 raise TypeError, 'list, set or zset required'
               end
        
        sorter = if order.include?('alpha')
                   if order.include?('desc')
                     lambda{|a, b| b <=> a}
                   else
                     lambda{|a, b| a <=> b}
                   end
                 elsif order.include?('desc')
                   lambda{|a, b| b.to_f <=> a.to_f}
                 else
                   lambda{|a, b| a.to_f <=> b.to_f}
                 end

        vals.sort!{|a, b| sorter.call(a, b)}
        
        if limit
          vals = vals[*limit]
        end

        if store
          with_type(store, 'list') do
            self.keyspace[store.to_s] = vals
          end
        end

        vals
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
          md[:type].dup
        else
          'none'
        end
      end

      # Strings

      def get(key)
        with_type(key, 'string') do
          expunge_if_expired(key)  
          v = self.keyspace[key.to_s]
          v.nil? ? nil : v.dup
        end
      end

      def set(key, val)
        with_type(key, 'string') do
          expunge_if_expired(key)
          v = if val.is_a?(::String)
                val.dup
              else
                val.to_s
              end
          self.keyspace[key.to_s] = v
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

        bitstring = self.get(key).unpack('B*')[0]
        if index < bitstring.length
          if RUBY_VERSION.match(/^1\.8/)
            bitstring[index].chr.to_i
          else
            bitstring[index].to_i
          end
        else
          0
        end
      end

      def setbit(key, index, value)
        raise ArgumentError, 'setbit takes a non-negative index' unless index > 0
        raise ArgumentError, 'setbit takes a 1 or 0 for the value' unless((0 == value) || (1 == value))

        bitstring = self.get(key).unpack('B*')[0]
        current_val = 0
        if index < bitstring.length
          current_val = if RUBY_VERSION.match(/^1\.8/)
                          bitstring[index].chr.to_i
                        else
                          bitstring[index].to_i
                        end
          bitstring[index] = value.to_s
        else
          bitstring << ('0' * (index - bitstring.length))
          bitstring << value.to_s
        end
        self.set(key, [bitstring].pack('B*'))
        current_val
      end

      def getrange(key, first_index, last_index)
        if self.exists(key)
          with_type(key, 'string') do
            arr = self.keyspace[key.to_s].bytes.to_a[first_index..last_index]
            if arr
              arr.map{|c| c.chr}.join('')
            else
              nil
            end
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
          v = val.to_s
          if padding_length > 0            
            #self.keyspace[key.to_s][length, padding_length + v.length] = ("\u0000" * padding_length) + v
            self.keyspace[key.to_s][length, padding_length + v.length] = ("\000" * padding_length) + v
          else
            self.keyspace[key.to_s][start_index, v.length] = v
          end
          self.strlen(key)
        end
      end

      def strlen(key)
        val = self.get(key)
        if val.nil?
          0
        else
          if "".respond_to?(:bytesize)
            val.bytesize
          else
            val.length
          end
        end
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
            val[start_index..stop_index] || [] ## never return nil -- happens if start_index is neg and before begining of list
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
          v = if val.is_a?(::String)
                val.dup
              else
                val.to_s
              end
          self.keyspace[key.to_s] << v
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
          v = if val.is_a?(::String)
                val.dup
              else
                val.to_s
              end
          self.keyspace[key.to_s].unshift(v)
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
            v = self.keyspace[key.to_s][ind]
            v.nil? ? nil : v.dup
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
            v = if val.is_a?(::String)
                  val.dup
                else
                  val.to_s
                end
            self.keyspace[key.to_s][ind] = v
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
            v = val.to_s
            iterator.each_with_index do |test, i|
              if test == v
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
              v = if val.is_a?(::String)
                    val.dup
                  else
                    val.to_s
                  end
              self.keyspace[key.to_s].insert(ind, v)
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

      # Set

      def sadd(key, val)
        with_type(key, 'set') do
          v = val.to_s
          if !self.exists(key)
            self.keyspace[key.to_s] = {}
          end
          if self.keyspace[key.to_s].has_key?(v)
            false
          else
            self.keyspace[key.to_s][v] = true
            true
          end
        end
      end

      def scard(key)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil?
            0
          else
            val.size
          end
        end
      end

      def smembers(key)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil?
           []
          else
            val.keys
          end
        end
      end

      def spop(key)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           nil
          else
            val = hsh.keys.sort{Kernel.rand}[0]
            self.keyspace[key.to_s].delete(val)
            if 0 == self.keyspace[key.to_s].size
              self.del(key)              
            end
            val
          end
        end
      end

      def sismember(key, val)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           false
          else
            hsh.has_key?(val.to_s)
          end
        end
      end

      def srem(key, val)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           false
          else
            !!hsh.delete(val.to_s)
          end
        end
      end

      def srandmember(key)
        with_type(key, 'set') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           nil
          else
            hsh.keys.sort{Kernel.rand}[0]
          end
        end
      end

      def smove(source_key, dest_key, val)
        if self.exists(source_key)
          if self.srem(source_key, val)
            self.sadd(dest_key, val)
            true
          else
            false
          end
        else
          false
        end
      end

      def sunion(*keys)
        raise ArgumentError, 'sunion needs at least one key' unless keys.size > 0
        union = self.smembers(keys.shift)
        while k = keys.shift
          union = union | self.smembers(k)
        end
        union
      end

      def sinter(*keys)
        raise ArgumentError, 'sinter needs at least one key' unless keys.size > 0
        inter = self.smembers(keys.shift)
        while k = keys.shift
          inter = inter & self.smembers(k)
        end
        inter
      end

      def sdiff(*keys)
        raise ArgumentError, 'sinter needs at least one key' unless keys.size > 0
        diff = self.smembers(keys.shift)
        while k = keys.shift
          diff = diff - self.smembers(k)
        end
        diff
      end

      def sunionstore(key, *other_keys)
        vals = self.sunion(*other_keys)
        vals.each{|v| self.sadd(key, v)}
        vals.size
      end

      def sinterstore(key, *other_keys)
        vals = self.sinter(*other_keys)
        vals.each{|v| self.sadd(key, v)}
        vals.size
      end

      def sdiffstore(key, *other_keys)
        vals = self.sdiff(*other_keys)
        vals.each{|v| self.sadd(key, v)}
        vals.size
      end

      # Sorted Sets

      def zadd(key, score, val)
        with_type(key, 'zset') do
          s = if score.is_a?(Numeric)
                score
              elsif score.is_a?(::String)
                (score.index('.') ? score.to_f : score.to_i)
              else
                raise ArgumentError, "score is not numeric"
              end
          if !self.exists(key)
            self.keyspace[key.to_s] = {:map => {}, :list => []}
          end
          ret = true
          v = val.to_s
          if self.keyspace[key.to_s][:map].has_key?(v)
            ret = false
          end
          self.keyspace[key.to_s][:map][v] = s
          self.resort(key)
          ret
        end
      end

      def zcard(key)
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil?
            0
          else
            val[:list].size
          end
        end
      end

      def zrange(key, start_index, stop_index, opts={})
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil? || (start_index >= val[:list].size) || ( (start_index < 0) && (stop_index < start_index) )
            []
          else
            ## emulate redis -- a neg start index before beginning meams the beginning
            if (start_index < 0) && (-start_index > val[:list].size)
              start_index = 0
            end
            if opts[:with_scores] || opts[:withscores]
              ret = []
              val[:list][start_index..stop_index].each do |v|
                ret << v
                ret << val[:map][v].to_s
              end
              ret
            else
              val[:list][start_index..stop_index] || [] ## never return nil
            end
          end
        end
      end

      def zrevrange(key, start_index, stop_index, opts={})
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil? || (start_index >= val[:list].size) || ( (start_index < 0) && (stop_index < start_index) )
            []
          else
            list = val[:list].reverse
            if opts[:with_scores] || opts[:withscores]
              ret = []
              list[start_index..stop_index].each do |v|
                ret << v
                ret << val[:map][v].to_s
              end
              ret
            else
              list[start_index..stop_index]
            end
          end
        end
      end

      def zrangebyscore(key, min, max, opts={})
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          val = self.keyspace[key.to_s]
          if val.nil?
            []
          else
            parse = lambda {|v|
              if v.is_a?(::String)
                if v[0] == '('[0]                  
                  [v[1..v.length-1].to_i, false]
                elsif '+inf' == v
                  [1.0/0, true]
                elsif '-inf' == v
                  [-1.0/0, true]
                else
                  [v.to_i, true]
                end
              else
                [v.to_i, true]
              end
              }
            min_int, min_incl = *parse.call(min)
            max_int, max_incl = *parse.call(max)

            ret = []

            pass = lambda { |v, op, incl, test|
              v.send( op + (incl ? '=' : ''), test)
            }

            val[:list].each do |v|
              if pass.call(val[:map][v], '>', min_incl, min_int) && pass.call(val[:map][v], '<', max_incl, max_int)
                ret << v
                if opts[:with_scores] || opts[:withscores]
                  ret << val[:map][v].to_s
                end
              end
            end
            if opts.has_key?(:limit)
              limit = if opts[:with_scores] || opts[:withscores]
                        opts[:limit].map{|x| x * 2}
                      else
                        opts[:limit]
                      end
              ret[limit[0], limit[1]]
            else
              ret
            end
          end
        end
      end

      def zrevrangebyscore(key, max, min, opts={})
        limit = opts.delete(:limit)
        ret = self.zrangebyscore(key, min, max, opts).reverse
        if limit
          ret[limit[0], limit[1]]
        else
          ret
        end
      end

      def zcount(key, min, max)
        self.zrangebyscore(key, min, max).size
      end

      def zrank(key, val)
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           nil
          else
            hsh[:list].index(val.to_s)
          end
        end
      end

      def zrevrank(key, val)
        r = self.zrank(key, val)
        if r
          self.keyspace[key.to_s][:list].size - (r + 1)
        else
          nil
        end
      end

      def zscore(key, val)
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           nil
          else
            v = hsh[:map][val.to_s]
            if v
              v.to_s
            else
              nil
            end
          end
        end
      end

      def zincrby(key, by, val)
        score = self.zscore(key, val) || '0'
        new_score = (score.index('.') ? score.to_f : score.to_i) + by
        self.zadd(key, new_score, val)
        new_score.to_s
      end

      def zrem(key, val)
        with_type(key, 'zset') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if hsh.nil?
           false
          else
            if hsh[:map].delete(val.to_s)
              self.resort(key)
              true
            else
              false
            end
          end
        end
      end

      def zremrangebyscore(key, min, max)
        vals = self.zrangebyscore(key, min, max)
        if vals.size > 0
          vals.each do |val|
            self.keyspace[key.to_s][:map].delete(val)
          end
          self.resort(key)
          vals.size
        else
          0
        end
      end

      def zremrangebyrank(key, start, stop)
        vals = self.zrange(key, start, stop)
        if vals.size > 0
          vals.each do |val|
            self.keyspace[key.to_s][:map].delete(val)
          end
          self.resort(key)
          vals.size
        else
          0
        end        
      end

      def zunionstore(key, other_keys, opts)
        raise ArgumentError, 'zunionstore needs at least one key' unless other_keys.size > 0
        raise ArgumentError, 'mismatch weights count' unless (!opts.has_key?(:weights) || (opts[:weights].size == other_keys.size))
        with_type(key, 'zset') do
          sorted_sets = other_keys.map{|k| self.keyspace[k.to_s]}.compact
          u = sorted_sets.pop
          if u
            weight_a = (opts.has_key?(:weights) ? opts[:weights].pop : 1)
            while ss = sorted_sets.pop
              weight_b = (opts.has_key?(:weights) ? opts[:weights].pop : 1)
              u = self.ss_union(u, ss, weight_a, weight_b, (opts.has_key?(:aggregate) ? opts[:aggregate] : 'sum')) ##@@ weights and agg
              weight_a = 1
            end
          else
            u = {:map => {}, :list => []}
          end
            self.keyspace[key.to_s] = u
          u[:list].size
        end
      end

      def zinterstore(key, other_keys, opts)
        raise ArgumentError, 'zinterstore needs at least one key' unless other_keys.size > 0
        with_type(key, 'zset') do
          sorted_sets = other_keys.map{|k| self.keyspace[k.to_s]}.compact
          i = sorted_sets.pop
          if i
            weight_a = (opts.has_key?(:weights) ? opts[:weights].pop : 1)
            while ss = sorted_sets.pop
              weight_b = (opts.has_key?(:weights) ? opts[:weights].pop : 1)
              i = self.ss_intersect(i, ss, weight_a, weight_b, (opts.has_key?(:aggregate) ? opts[:aggregate] : 'sum')) ##@@ weights and agg
              weight_a = 1
            end
          else
            i = {:map => {}, :list => []}
          end
          self.keyspace[key.to_s] = i
          i[:list].size
        end
      end

      # Hashes

      def hget(key, field)
        with_type(key, 'hash') do
          expunge_if_expired(key)  
          hsh = self.keyspace[key.to_s]
          if !hsh.nil? && hsh.has_key?(field.to_s)
            hsh[field.to_s].dup
          else
            nil
          end
        end
      end

      def hexists(key, field)
        with_type(key, 'hash') do
          self.exists(key) && self.keyspace[key.to_s].has_key?(field.to_s)
        end
      end

      def hset(key, field, val)
        with_type(key, 'hash') do
          f = field.to_s
          v = if val.is_a?(::String)
                val.dup
              else
                val.to_s
              end
          if !self.exists(key)
            self.keyspace[key.to_s] = {}
          end
          ret = !self.keyspace[key.to_s].has_key?(f)
          self.keyspace[key.to_s][f] = v
          ret
        end
      end

      def hgetall(key)
        with_type(key, 'hash') do
          hsh = self.keyspace[key.to_s]
          if hsh
            hsh.dup
          else
            {}
          end
        end
      end

      def hkeys(key)        
        if hsh = self.hgetall(key)
          hsh.keys
        else
          []
        end
      end

      def hvals(key)        
        if hsh = self.hgetall(key)
          hsh.values
        else
          []
        end
      end

      def hlen(key)        
        if hsh = self.hgetall(key)
          hsh.size
        else
          0
        end
      end

      def hdel(key, field)
        with_type(key, 'hash') do
          self.exists(key) && !!self.keyspace[key.to_s].delete(field.to_s)
        end
      end

      def hincrby(key, field, by)
        raise "value (#{by}) is not an integer" unless by.is_a?(::Integer)
        val = self.hget(key, field)
        new_val = val.to_i + by
        self.hset(key, field, new_val)
        new_val
      end
      
      def hmget(key, *fields)
        fields.map{|f| self.hget(key, f)}        
      end

      def hmset(key, *pairs)
        i = 0
        while i < pairs.length
          self.hset(key, pairs[i], pairs[i+1])
          i += 2
        end
        true
      end

      def hsetnx(key, field, val)
        if self.hexists(key, field)
          false
        else
          self.hset(key, field, val)
        end
      end

      # Transactions

      def multi
        if @multi_mode
          raise "multi calls can't be nested"
        else
          @multi_mode = true
          @multi_calls = []
          if block_given?
            begin
              yield
            rescue Exception => e
              self.discard
              raise e
            end
            self.exec
          end
        end
      end

      def exec
        if @multi_mode
          @multi_mode = false
          ret = []
          @multi_calls.each do |call|
            ret << (self.call *call)
          end
          @multi_calls = []
          ret
        else
          raise "exec without a multi"
        end
      end

      def discard
        if @multi_mode
          @multi_mode = false
          @multi_calls = []          
        else
          raise "discard without a multi"
        end
      end

      def watch(*keys)
        if @multi_mode
          raise "watch inside multi not allowed"
        end
        ## nothing, we are non concurrent
        true
      end

      def unwatch
        ## nothing, we are non concurrent
        true
      end

      def flushdb
        if self.shared?
          TransientStore::KEYSPACES[self.name] = {}
          TransientStore::MDSPACES[self.name]  ={}
        else
          @keyspace = {}
          @mdspace = {}
        end
      end

      # non-public helpers for redis methods
      protected

      def resort(key)
        self.keyspace[key.to_s][:list] = do_sort(self.keyspace[key.to_s][:map])
      end
      
      def do_sort(map)
        map.keys.sort do |a, b| 
          score = (map[a] <=> map[b])
          if 0 == score
            a <=> b
          else
            score
          end
        end
      end

      def ss_union(a, b, weight_a, weight_b, aggregate)
        self.do_ss_calc( (a[:list] | b[:list] ), a, b, weight_a, weight_b, aggregate )
      end

      def ss_intersect(a, b, weight_a, weight_b, aggregate)
        self.do_ss_calc( (a[:list] & b[:list] ), a, b, weight_a, weight_b, aggregate )
      end

      def do_ss_calc(set, a, b, weight_a, weight_b, aggregate)
        r = {:map => {}, :list => []}
        set.each do |k|
          a_score = a[:map].has_key?(k) && (a[:map][k] * weight_a)
          b_score = b[:map].has_key?(k) && (b[:map][k] * weight_b)
          r[:map][k] = if a_score && b_score
                         case aggregate.downcase
                         when 'sum'
                           a_score + b_score
                         when 'min'
                           [a_score, b_score].min
                         when 'max'
                           [a_score, b_score].max
                         else
                           raise ArgumentError, "Invalid aggregate: #{aggregate}"
                         end
                       elsif a_score
                         a_score
                       else
                         b_score
                       end
        end
        r[:list] = do_sort(r[:map])
        r
      end

      public
      ## end of redis methods

      def method_missing(*args)
        puts "unimplemented: #{args}"
      end

      def inspect
        "<#{self.class} @name=#{self.name.inspect}>"
      end

    end
  end
end
