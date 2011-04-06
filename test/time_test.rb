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

  def test_mask
    raw_time = Time.now
    t = Store.init_time(random_key, raw_time)

    assert_equal raw_time.zone, t.zone

    assert_equal raw_time.localtime, t.localtime.to_time
    assert_equal raw_time.zone, t.zone
    assert_equal raw_time.to_s, t.to_s

    if Time.now.method(:localtime).arity > 0
      assert_equal raw_time.localtime("-08:00"), t.localtime("-08:00").to_time
      assert_equal raw_time.zone, t.zone
      assert_equal raw_time.to_s, t.to_s
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
