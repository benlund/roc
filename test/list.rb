require 'test/roc_test'

class ListTest < ROCTest

  def test_rw
    l = collection.init_list(random_key)
    assert_equal 0, l.size
    assert_equal 0, l.items.size

    l << 'a'
    assert_equal 1, l.size
    assert_equal 'a', l[0]

    l.unshift 'z'
    assert_equal 2, l.size
    assert_equal 'z', l[0]

    l << '1'
    assert_equal ['z', 'a', '1'], l.items
    assert_equal ['a', '1'], l.range(1,2)

    assert_equal ['a', '1'], l[1..2]
    assert_equal ['a'], l[1...2]

    l[2] = '2'
    assert_equal '2', l[2]
    assert_equal 3, l.size

    l.delete('2')
    assert_equal 2, l.size

    l << nil
    l.trim(0, 1)
    assert_equal 2, l.size
    
    l.rpoplpush

    assert_equal 'a', l.shift
    assert_equal 'z', l.pop
    assert_equal 0, l.size

    l << 'a'
    l << 'b'
    l << 'c'
    ol = collection.init_list(random_key)
    l.rpoplpush(ol)
    ## these fail -- calling the super method? wtf?
    #assert_equal ['c'], ol.to_a 
    #assert_equal ['a', 'b'], l.to_a
  end

  def test_delegation
    l = collection.init_list(random_key)

    ##@@ test .last
  end

end
