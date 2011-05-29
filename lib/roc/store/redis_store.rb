if RUBY_VERSION.match(/^1\.8/)
  require 'rubygems'
end
require 'redis'
require 'roc/ext/redis_ext'
require 'roc/store/object_initializers'

require 'forwardable'

module ROC
  module Store
    class RedisStore
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

      def_delegators :connection, :multi, :exec, :discard, :watch, :unwatch, :flushdb

      def inspect
        "<#{self.class} @connection=#{self.connection.inspect}>"
      end

      def enable_eval
        require 'roc/store/redis_eval'
      end

    end
  end
end
