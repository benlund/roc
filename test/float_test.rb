require File.join(File.dirname(__FILE__), 'roc_test')

class FloatTest < ROCTest

  def test_rw
    f = Store.init_float(random_key)
    assert_nil f.value
    assert_equal 0.0, f.to_f
    assert_equal 0, f.to_i
    f.value = 2.345
    assert_equal 2.345, f.value
  end

  def test_infinite
    f = Store.init_float(random_key, (1.0 / 0))
    assert_equal 1, f.infinite?
    f.value = (-1.0 / 0)
    assert_equal -1, f.infinite?
  end

  def test_delegation
    f = Store.init_float(random_key)
    num = 2.345
    f.value = num
    assert_equal (num - 1.0), (f - 1.0)
    assert_equal (num + 1.0), (f + 1.0)
    assert_equal (num / 0.5), (f / 0.5)
    assert_equal (num * 3.2), (f * 3.2)    
  end

end
