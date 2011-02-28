require 'test/roc_test'

class SortedSetTest < ROCTest

  def test_rw

    s = collection.init_sorted_set(random_key)
    assert_equal 0, s.size
    assert_equal 0, s.items.size
    
    s.add('a', 1)
    s.add('a', 2)
    assert_equal 1, s.size
    assert_equal 'a', s[0]

    s << ['z', 1]
    assert s.include?('z')
    assert !s.include?('zzz')

    assert_equal ['z', 'a'], s.items

    s << {:value => 'y', :score => 6}
    s << {:value => 'w', :score => 6}
    assert_equal 4, s.size

    s.delete 'z'
    assert_equal 3, s.size

    os = collection.init_sorted_set(random_key)
    us = collection.init_sorted_set(random_key)
    is = collection.init_sorted_set(random_key)

    os << ['z', 1]
    os << ['y', 6]
    us.set_as_union_of(s, os)
    is.set_as_intersect_of(s, os)

    assert_equal ['z', 'a', 'w', 'y'], us.items
    assert_equal ['y'], is.items

  end

  def test_delegation
  end

end


## @@ list and set test delegation not finished
## @@ stack level too deep happens when method missing called with unimplemented method on delegate

## not all methids iplemented in sorted_set (others?)

## sorted_set union etc need aggreaagte and weight options

## check set_as_union_of difference between set and sorted set
