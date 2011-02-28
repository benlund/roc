require 'test/roc_test'

class SetTest < ROCTest

  def test_rw
    s = collection.init_set(random_key)
    assert_equal 0, s.size
    assert_equal 0, s.items.size

    s << 'a'
    s << 'a'
    assert_equal 1, s.size
    assert_equal 'a', s.pop

    s << 'z'
    assert s.include?('z')
    assert !s.include?('zzz')
    
    s << 'y'
    s << 'w'
    assert ['z','y','w'].include?(s.rand_item)
    assert_equal 3, s.size

    s.delete 'z'
    assert_equal 2, s.size

    os = collection.init_set(random_key)
    s.move_into(os, 'y')
    assert_equal 1, s.size
    assert_equal 1, os.size
    s.move_into(os, 'xxx')
    assert_equal 1, s.size
    assert_equal 1, os.size

    s << 'y'
    os << 'z'

    assert_equal ['w', 'y', 'z'], s.union(os).sort
    assert_equal ['y'], s.intersect(os).sort

    assert_equal ['w'], (s - os).sort
    assert_equal ['z'], (os - s).sort

    i_set = collection.init_set(random_key)
    u_set = collection.init_set(random_key)
    d1_set = collection.init_set(random_key)
    d2_set = collection.init_set(random_key)
    i_set.set_as_intersect_of(s, os)
    u_set.set_as_union_of(s, os)
    d1_set.set_as_diff_of(s, os)
    d2_set.set_as_diff_of(os, s)

    assert_equal ['w', 'y', 'z'], u_set.items.sort
    assert_equal ['y'], i_set.items.sort
    assert_equal ['w'], d1_set.items.sort
    assert_equal ['z'], d2_set.items.sort
  end

  def test_delegation
    
  end

end
