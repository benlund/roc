require 'rufus/lua'
module ROC
  module Store
    module TransientEval

      protected

      def eval(script, num_key_args, *args)
        s = Rufus::Lua::State.new
        s.function('redis') do |*args|
          command = args.shift.to_sym
          self.call command, *args
        end
        s['KEYS'] = args.slice(0...num_key_args)
        s['ARGV'] = args.slice(num_key_args...args.size)
        res = s.eval(script)
        if res.is_a?(Rufus::Lua::Table)
          res.to_ruby
        else
          res
        end
      end

    end
  end
end
