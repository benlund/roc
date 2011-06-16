require 'roc/types/method_generators'

module ROC
  module Types
    module AllTypes
      extend(ROC::Types::MethodGenerators)

      zero_arg_method :exists
     
      alias exists? exists
      
      zero_arg_method :del
      
      alias forget del

      nonserializing_method :expire

      nonserializing_method :expireat

      zero_arg_method :ttl

      zero_arg_method :persist
      
      def eval(script, *args)
        keys = [self.key]
        argv = []
        args.each do |a|
          if a.is_a?(ROC::Base)
            keys << a.key
          else
            argv << a
          end
        end
        self.storage.call :eval, script, keys.size, *keys, *argv
      end

    end
  end
end


