require File.join(File.dirname(__FILE__), 'roc_test')

class SortedSetTest < ROCTest

  def test_rw

    s = Store.init_sorted_set(random_key)
    assert_equal 0, s.size
    assert_equal [], s.values
    assert_equal [], s.to_a
    
    s.add(1, 'a')
    s.add(2, 'a')
    assert_equal 1, s.size
    assert_equal 'a', s[0]

    s << [1, 'z']
    assert s.include?('z')
    assert !s.include?('zzz')

    assert_equal ['z', 'a'], s.values

    s << {:value => 'y', :score => 6}
    s << {:value => 'w', :score => 6}
    assert_equal ['z', 'a', 'w', 'y'], s.values

    assert s.rem('z')
    assert !s.rem('z')
    assert_equal 3, s.size

    os = Store.init_sorted_set(random_key)
    us = Store.init_sorted_set(random_key)
    is = Store.init_sorted_set(random_key)

    os << [1, 'z']
    os << [6, 'y']

    #defaults
    us.set_as_union_of(s, os)
    is.set_as_intersect_of(s, os)
    assert_equal ['z', 'a', 'w', 'y'], us.values
    assert_equal ['z', '1', 'a', '2', 'w', '6', 'y', '12'], us.values(:with_scores => true)
    assert_equal ['y'], is.values
    assert_equal ['y', '12'], is.values(:with_scores => true)

    os.add(7, 'w')

    #s : [2, 'a'], [6, 'w'], [6, 'y']
    #os: [1, 'z'], [6, 'y'], [7, 'w']

    #weights
    us.set_as_union_of(s, os, :weights => [10, 1])
    is.set_as_intersect_of(s, os, :weights => [10, 1])
    assert_equal [ 'z', 'a', 'y', 'w'], us.values
    assert_equal [ 'z', '1', 'a', '20', 'y', '66', 'w', '67'], us.values(:with_scores => true)
    assert_equal ['y', 'w'], is.values
    assert_equal ['y', '66', 'w', '67'], is.values(:with_scores => true)    

    #aggregate

    us.set_as_union_of(s, os, :aggregate => 'max')
    is.set_as_intersect_of(s, os, :aggregate => 'max')
    assert_equal [ 'z', 'a', 'y', 'w'], us.values
    assert_equal [ 'z', '1', 'a', '2', 'y', '6', 'w', '7'], us.values(:with_scores => true)
    assert_equal ['y', 'w'], is.values
    assert_equal ['y', '6', 'w', '7'], is.values(:with_scores => true)    

    us.set_as_union_of(s, os, :aggregate => 'min')
    is.set_as_intersect_of(s, os, :aggregate => 'min')
    assert_equal [ 'z', 'a', 'w', 'y'], us.values
    assert_equal [ 'z', '1', 'a', '2', 'w', '6', 'y', '6'], us.values(:with_scores => true)
    assert_equal ['w', 'y'], is.values
    assert_equal ['w', '6', 'y', '6'], is.values(:with_scores => true)    

    return


    ##@@

  end

  def test_delegation
  end

end


## @@ list and set test delegation not finished
## @@ stack level too deep happens when method missing called with unimplemented method on delegate

## not all methids iplemented in sorted_set (others?)

## sorted_set union etc need aggreaagte and weight options

## check set_as_union_of difference between set and sorted set
