require 'test/unit'

require 'redis-roc'

Store = if ENV['ROC_STORE'].nil?
          ROC::Store::TransientStore.new
        elsif ENV['ROC_STORE'] =~ /redis:/
          ROC::Store::RedisStore.new(:url => ENV['ROC_STORE'])
        else
          ROC::Store::TransientStore.new(ENV['ROC_STORE'])
        end

class ROCTest < Test::Unit::TestCase

  def setup
    @keys_used = []
  end
  
  def teardown
    @keys_used.each do |k|
      Store.call(:del, k)
    end
  end
    
  def random_key
    k = ['ROCTest', 'random', Time.now.to_f, Kernel.rand(500000)].join(':')
    @keys_used << k
    k
  end

  def test_connection
    k = random_key
    v = Kernel.rand(20000).to_s
    Store.call(:set, k, v)
    assert_equal(Store.call(:get, k), v)
  end

end
