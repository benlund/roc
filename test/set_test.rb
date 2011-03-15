require File.join(File.dirname(__FILE__), 'roc_test')

class SetTest < ROCTest

  def test_rw
    s = Store.init_set(random_key)
    assert_equal 0, s.size
    assert_equal [], s.values
    assert_equal [], s.to_a

    assert(s << 'a')
    assert(!(s << 'a'))
    assert_equal 1, s.size
    assert_equal 'a', s.pop
    assert !s.exists?

    assert(s << 'z')
    assert s.include?('z')
    assert !s.include?('zzz')
    
    assert(s << 'y')
    assert(s << 'w')
    assert ['z','y','w'].include?(s.rand_member)
    assert_equal ['w','y','z'], s.values.sort
    assert_equal 3, s.size

    assert s.rem('z')
    assert_equal ['w','y'], s.values

    os = Store.init_set(random_key)
    assert s.move_into(os, 'y')
    assert_equal 1, s.size
    assert_equal 1, os.size
    assert !s.move_into(os, 'xxx')
    assert_equal 1, s.size
    assert_equal 1, os.size

    s << 'y'
    os << 'z'

    assert_equal ['w', 'y', 'z'], (s | os).sort
    assert_equal ['y'], (s & os).sort
    assert_equal ['w'], (s - os).sort
    assert_equal ['z'], (os - s).sort

    i_set = Store.init_set(random_key)
    u_set = Store.init_set(random_key)
    d1_set = Store.init_set(random_key)
    d2_set = Store.init_set(random_key)

    assert_equal 3, u_set.set_as_union_of(s, os)
    assert_equal 1, i_set.set_as_intersect_of(s, os)
    assert_equal 1, d1_set.set_as_diff_of(s, os)
    assert_equal 1, d2_set.set_as_diff_of(os, s)

    assert_equal ['w', 'y', 'z'], u_set.values.sort
    assert_equal ['y'], i_set.values.sort
    assert_equal ['w'], d1_set.values.sort
    assert_equal ['z'], d2_set.values.sort
  end

  def test_delegation
    # @@
  end

end
