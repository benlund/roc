require File.join(File.dirname(__FILE__), 'roc_test')

class KeyOperationsTest < ROCTest

  def test_set_del_exists
    str = Store.init_string(random_key)
    assert !str.exists?
    str.value = 'test'
    assert str.exists?
    str.forget
    assert !str.exists?
  end


  def test_expires
    str = Store.init_string(random_key, 'someseed')
    assert(str.ttl == -1)
    assert str.expire(10)
    assert(str.ttl > 0)

    when_to_expire = Time.now.to_i + 20
    assert str.expireat(when_to_expire)
    assert_equal str.ttl, (when_to_expire - Time.now.to_i)

    assert str.persist
    assert(str.ttl == -1)
  end

  def test_keys
    r1 = random_key
    r2 = random_key
    r3 = random_key
    r4 = random_key

    s1 = Store.init_string(r1, 'someseed')
    s2 = Store.init_list(r2, ['someseed', 'someotherseed'])
    s3 = Store.init_set(r3, ['someseed', 'someotherseed'])
    s4 = Store.init_sorted_set(r4, [[1, 'someseed'], [2, 'someotherseed']])

    assert_equal @keys_used.sort, Store.keys.sort
    assert @keys_used.include?(Store.randomkey)

    assert(Store.rename r1, r2)
    assert !s1.exists?

    assert_raises ArgumentError do 
      Store.rename r1, r2
    end

    r5 = random_key

    assert !(Store.renamenx r3, r4)
    assert (Store.renamenx r3, r5)
    assert_equal ['someseed', 'someotherseed'], Store.init_set(r5).values
  end

end
