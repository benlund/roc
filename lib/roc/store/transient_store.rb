require 'roc/store/object_initializers'
module ROC
  module Store
    class TransientStore
      include ObjectInitializers

      KEYSPACES = {}

      attr_reader :name

      def initialize(name)
        @name = name.to_s
        TransientStore::KEYSPACES[@name] ||= {}
      end

      def keyspace
        TransientStore::KEYSPACES[self.name]
      end

      def inspect
        "<#{self.class} @name=#{self.name.inspect}>"
      end

    end
  end
end
