if RUBY_VERSION.match(/^1\.8/)
  require 'rubygems'
end
require 'redis'
require 'roc/ext/redis_ext'
require 'roc/store/roc_store'
require 'roc/store/object_initializers'

require 'forwardable'

module ROC
  module Store
    class RedisStore < ROCStore
      include ObjectInitializers
      extend Forwardable

      attr_reader :connection

      def initialize(connection)
        if connection.is_a?(Redis)
          @connection = connection
        else
          @connection = Redis.connect(connection)
        end
      end

      def call(method_name, *args)
        self.connection.send method_name, *args
      end

      def_delegators :connection, :watch, :unwatch, :flushdb

      def multi
        @in_multi = true
        if block_given?          
          ret = self.connection.multi do
            yield
          end           
          @in_multi = false
        else
          ret = self.connection.multi
        end
        ret
      end

      def exec
        ret = self.connection.exec
        if @in_multi
          @in_multi = false
        end
        ret
      end

      def discard
        ret = self.connection.discard
        if @in_multi
          @in_multi = false
        end
        ret
      end

      def in_multi?
        !!@in_multi
      end

      def inspect
        "<#{self.class} @connection=#{self.connection.inspect}>"
      end

      def enable_eval
        require 'roc/store/redis_eval'
      end

    end
  end
end
