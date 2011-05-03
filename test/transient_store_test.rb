require 'test/unit'

require 'roc'

class TransientStoreTest < Test::Unit::TestCase

  Store = ROC::Store::TransientStore.new('transient_store_unit_test')
    
  def random_key
    ['TransientStoreTest', 'random', Time.now.to_f, Kernel.rand(500000)].join(':')
  end

  ## all objects returned from calls should be dups, not references, so client code can't modify
  def test_dups

    k = random_key
    Store.set k, 'hi'

    #get
    (Store.get k) << 'gh'
    assert_equal 'hi', (Store.get k) 

    # type
    (Store.type k) << 'nonsense'
    assert_equal 'string', (Store.type k)

    # set
    val = 'hi there'
    Store.set k, val
    val << ' and here'
    assert_equal 'hi there', (Store.get k)
    
    lk = random_key

    #rpush
    val = 'first'
    Store.rpush lk, val
    val << '_and_second'
    assert_equal 'first', (Store.lindex lk, 0)

    # lpush
    val = 'new first'
    Store.lpush lk, val
    val << ' or is it'
    assert_equal 'new first', (Store.lindex lk, 0)

    
    #lindex
    val = 'another new'
    Store.lpush lk, val
    (Store.lindex lk, 0) << ' with suffix'
    assert_equal 'another new', (Store.lindex lk, 0)

    #lset
    val = 'second'
    Store.lset lk, 1, val
    val << '_and_third'
    assert_equal 'second', (Store.lindex lk, 1)

    #linsert
    Store.del lk
    Store.rpush lk, 'first'
    Store.rpush lk, 'second'
    val = 'third'
    Store.linsert lk, 'after', 'second', val
    val << '_and_fourth'
    assert_equal 'third', (Store.lindex lk, -1)

    sk = random_key

    #sadd
    val = 'member'
    Store.sadd sk, val
    val << 'modification'
    assert (Store.sismember sk, 'member')
    
    ssk = random_key

    #zadd
    val = 'member'
    score = 1.2
    Store.zadd ssk, score, val
    val << 'modification'
    ##perturb score ??
    assert_equal '1.2', (Store.zscore ssk, 'member')
    assert_equal ['member'], (Store.zrange ssk, 0, 0)

    #zscore
    (Store.zscore ssk, 'member') << '3'
    assert_equal '1.2', (Store.zscore ssk, 'member')

    hk = random_key
    hkk = random_key

    Store.hset hk, hkk, 'hi'

    #hget
    (Store.hget hk, hkk) << 'gh'
    assert_equal 'hi', (Store.hget hk, hkk) 

    #hset
    val = 'hi there'
    Store.hset hk, hkk, val
    val << ' and here'
    assert_equal 'hi there', (Store.hget hk, hkk)
   
    #hgetall
    hsh = Store.hgetall hk
    hsh['another'] = 'blah'
    assert_nil Store.hget hk, 'another'

  end

  def test_isolated
    store1 = ROC::Store::TransientStore.new
    store2 = ROC::Store::TransientStore.new

    store1.set 'hi', 'ben'
    assert_nil(store2.get 'hi')
  end

  def test_shared

    store1 = ROC::Store::TransientStore.new('transient_store_unit_shared_test')
    store2 = ROC::Store::TransientStore.new('transient_store_unit_shared_test')

    store1.set 'hi', 'ben'
    assert_equal 'ben', (store2.get 'hi')

  end

end
