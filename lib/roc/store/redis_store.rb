require 'roc/store/object_initializers'
module ROC
  module Store
    class RedisStore
      STORAGE_TYPE_PREFIX = 'R'
      include ObjectInitializers

      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

    end
  end
end
