require File.join(File.dirname(__FILE__), 'roc_test')

class TimeTest < ROCTest

  def test_rw
    t = Store.init_time(random_key)
    assert_equal Time.at(0), t.to_time
    now = Time.now
    t.value = now
    assert_equal now, t.value
    assert_equal now.to_i, t.value.to_i
    assert_equal now.to_f, t.value.to_f
    assert_equal now.usec, t.value.usec
    if Time.now.respond_to?(:nsec)
      assert_equal now.nsec, t.value.nsec
    end
  end

  def test_delegation
    t = Store.init_time(random_key)
    now = Time.now
    t.value = now
    before = Time.at(1)
    assert_equal (now - before), (t - before)
    assert_equal now.usec, t.usec
  end

end
