require 'rufus/lua'
module ROC
  module Store
    module TransientEval

      protected

      def eval(script, num_key_args, *args)
        s = Rufus::Lua::State.new

        s['KEYS'] = args.slice(0...num_key_args)
        s['ARGV'] = args.slice(num_key_args...args.size)
        s['redis'] = {}

        s.function('redis.call') do |*args|
          command = args.shift.to_sym
          self.call command, *args
        end
        s.function('redis.log') do |*args|
          puts args.map{|x| rec_to_r(x)}.join(' ')
        end

        res = s.eval(script)
        rec_to_r(res)
      end

      def rec_to_r(obj)
        if obj.is_a?(Rufus::Lua::Table)
          robj = obj.to_ruby
          if robj.is_a?(Array)
            robj.map{|x| rec_to_r(x)}
          elsif robj.is_a?(Hash)
            Hash[robj.map{|pair| [pair[0], rec_to_r(pair[1])]}]
          end
        else
          obj
        end
      end

    end
  end
end
