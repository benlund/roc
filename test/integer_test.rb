require File.join(File.dirname(__FILE__), 'roc_test')

class IntegerTest < ROCTest

  def test_rw
    int = Store.init_integer(random_key)
    assert_equal nil, int.to_i
    int.increment
    int.increment
    assert_equal 2, int.value
    int.decrement
    assert_equal 1, int.value
    int.increment(5)
    assert_equal 6, int.value
    int.decrement(3)
    assert_equal 3, int.value
    int.value = 10
    assert_equal 10, int.value    
  end

  def test_delegation
    int = Store.init_integer(random_key, 0)
    assert_equal 3, (int + 3)
    assert_equal -3, (int - 3)
    int.increment(2)
    assert_equal(1, int / 2)
    assert_equal(6, int * 3)
  end

end
