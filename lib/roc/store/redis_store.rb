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
        @connection = connection
      end

      def call(method_name, *args)
        self.connection.send method_name, *args
      end

      def_delegators :connection, :multi, :exec, :discard, :watch, :unwatch

      def inspect
        "<#{self.class} @connection=#{self.connection.inspect}>"
      end

    end
  end
end
