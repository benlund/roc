require File.join(File.dirname(__FILE__), 'roc_test')

class ListTest < ROCTest

  def test_rw
    l = Store.init_list(random_key)
    assert_equal [], l.values
    assert_equal [], l.to_a
    assert_equal 0, l.size

    l << 'a'
    assert_equal 1, l.size
    assert_equal ['a'], l.range(0, 0)
    assert_equal ['a'], l.range(0, -1)
    assert_equal ['a'], l.range(-1, -1)

    l.unshift 'z'
    assert_equal 2, l.size
    assert_equal 'z', l[0]

    l << '1'
    assert_equal ['z', 'a', '1'], l.values
    assert_equal ['a', '1'], l.range(1,2)

    assert_equal '1', l.pop
    assert_equal 'z', l.shift
    assert_equal ['a'], l.values

    assert_raises ArgumentError do 
      l.set(1, '2')
    end

    l << '2'
    assert_equal ['a', '2'], l.values

    l.set(1, 'b')
    assert_equal 'b', l.index(1)
    assert_equal 2, l.size
    assert_equal ['a', 'b'], l.values

    3.times do 
      l << 'c'
    end
    l << 'x'
    3.times do 
      l << 'c'
    end    
    assert_equal 9, l.size
    assert_equal 0, l.rem(0, 'y')
    assert_equal 2, l.rem(2, 'c')
    assert_equal ['a', 'b', 'c', 'x', 'c', 'c', 'c'], l.values
    assert_equal 2, l.rem(-2, 'c')
    assert_equal ['a', 'b', 'c', 'x', 'c'], l.values
    assert_equal 2, l.rem(0, 'c')
    assert_equal ['a', 'b', 'x'], l.values

    assert l.trim(0, 1)
    assert_equal ['a', 'b'], l.values
    
    assert_equal 'b', l.rpoplpush
    assert_equal ['b', 'a'], l.values

    ol = Store.init_list(random_key)
    l.rpoplpush(ol)
    assert_equal ['b'], l.values
    assert_equal ['a'], ol.values

    return 

    ## @@

  end

  def test_shortcuts
    #    assert_equal ['a', '1'], l[1..2]
    # assert_equal ['a'], l[1...2]

  end

  def test_delegation
    l = Store.init_list(random_key)

    ##@@ test .last
  end

end
