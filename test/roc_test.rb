require 'test/unit'
require 'rubygems'
require 'redis'

require 'lib/roc'

class ROCTest < Test::Unit::TestCase

   def setup
     @keys_used = []
     @connection = Redis.new(:db => 13)
     @collection = ROC::Collection.new(@connection)
   end

   def teardown
     @keys_used.each do |k|
       @connection.del k
     end
   end

   def collection
     @collection
   end

   def random_key
     k = ['ROCTest', 'random', Time.now.to_f, Kernel.rand(500000)].join(':')
     @keys_used << k
     k
   end

   def test_connection
     k = random_key
     v = Kernel.rand(20000).to_s
     @connection.set(k, v)
     assert_equal(@connection.get(k), v)
   end

end
