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

end
