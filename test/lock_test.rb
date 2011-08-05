require File.join(File.dirname(__FILE__), 'roc_test')

class LockTest < ROCTest

  def test_rw

    l = Store.init_lock(random_key)

    assert l.lock(Time.now + 3)
    assert !l.lock(Time.now + 3)
    assert l.locked?

    sleep 3

    assert !l.locked?
    assert l.lock(Time.now + 3)
    assert !l.lock(Time.now + 3)

    l.unlock

    now = Time.now
    assert l.lock(now + 3)
    l.when_locked(now + 3) do
      waited_for = Time.now.to_i - now.to_i
      assert_equal 3, waited_for
    end

    now = Time.now
    assert l.lock(now + 3)

    l.wait_until_not_locked
    waited_for = Time.now.to_i - now.to_i
    assert_equal 3, waited_for

    counter = 0

    now = Time.now
    l.when_locked(now + 10) do
      counter += 1

      l.locking_if_necessary(now + 10) do
        counter += 1
      end
    end

    assert_equal 2, counter    

  end

end
