require 'test/roc_test'

class TimeTest < ROCTest

  def test_rw
    t = collection.init_time(random_key)
    assert_equal Time.at(0), t.to_time
    now = Time.now
    t.value = now
    assert_equal now, t.value
    assert_equal now.to_i, t.value.to_i
  end

  def test_delegation
    t = collection.init_time(random_key)
    now = Time.now
    t.value = now
    before = Time.at(1)
    assert_equal (now - before), (t - before)
  end

end
