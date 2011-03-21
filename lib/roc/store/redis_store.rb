require 'redis'
require 'roc/ext/redis_ext'
require 'roc/store/object_initializers'

module ROC
  module Store
    class RedisStore
      include ObjectInitializers

      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def call(method_name, *args)
        self.connection.send method_name, *args
      end

      def inspect
        "<#{self.class} @connection=#{self.connection.inspect}>"
      end

    end
  end
end
