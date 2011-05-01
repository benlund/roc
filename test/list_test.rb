require File.join(File.dirname(__FILE__), 'roc_test')

class ListTest < ROCTest

  def test_find
    k = random_key
    obj = Store.find(k)
    assert_nil obj

    Store.init_list(k, ['dsdfsd'])
    obj = Store.find(k)
    assert_equal ROC::List, obj.class
    assert_equal ['dsdfsd'], obj.values
  end

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

    assert_raises ArgumentError, RuntimeError do 
      l.set(1, '2')
    end

    l << '2'
    assert_equal ['a', '2'], l.values

    assert l.set(1, 'b')
    assert_equal 'b', l.index(1)
    assert_nil l.index(2)
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

    assert_equal 2, l.lpushx('a')
    assert_equal ['a', 'b'], l.values
    assert_equal 2, ol.rpushx('b')
    assert_equal ['a', 'b'], ol.values

    new_l = Store.init_list(random_key)
    assert_equal 0, new_l.lpushx('a')
    assert !new_l.exists
    assert_equal 0, new_l.rpushx('a')
    assert !new_l.exists

    assert_equal 3, l.insert_after('b', 'c')
    assert_equal ['a', 'b', 'c'], l.values
    assert_equal 4, l.insert_before('c', 'x')
    assert_equal ['a', 'b', 'x', 'c'], l.values
    assert_equal -1, l.insert_before('y', 'z')
    assert_equal ['a', 'b', 'x', 'c'], l.values
    assert_equal 0, new_l.insert_before(1, 1)

    ## sort

    assert_equal ['a', 'b', 'c', 'x'], l.sort(:order => 'alpha')
    assert_equal ['x', 'c', 'b', 'a'], l.sort(:order => 'alpha desc')
    assert_equal ['x', 'c'], l.sort(:order => 'alpha desc', :limit => [0, 2])
    

    ## empty it

    l.pop
    l.pop
    l.pop
    l.pop

    ## regression test
    assert_nil l.last

    #sort numbers

    l << '1.1'
    l << '0.2'
    l << '47'

    assert_equal ['0.2', '1.1', '47'], l.sort
    assert_equal ['47', '1.1', '0.2'], l.sort(:order => 'desc')

    sl = Store.init_list(random_key)

    l.sort(:store => sl)
    assert_equal ['0.2', '1.1', '47'], sl.values
  end

  def test_shortcuts

    l = Store.init_list(random_key, ['a', 'b', 'c', 'd', 'e', 'f'])

    assert_equal 'a', l.first
    assert_equal 'f', l.last

    assert_equal 'b', l[1]
    assert_equal ['c', 'd', 'e'], l[2..4]
    assert_equal ['c', 'd'], l[2...4]

    assert( l[1] = 'x' )
    assert_equal ['a', 'x', 'c', 'd', 'e', 'f'], l.values

    assert_raises ArgumentError do
      l[1..2] = 'x'
    end

    assert_raises ArgumentError do
      l[1,2] = 'x'
    end

  end

  def test_mask

    # implemented

    l = Store.init_list(random_key, ['1','2','1','2','1'])
    assert_equal '1', l.delete('1')
    assert_equal ['2','2'], l.values

    assert_equal l, l.push('3', '3')
    assert_equal ['2','2', '3', '3'], l.values

    assert_equal '3', l.pop
    assert_equal ['3'], l.pop(1)

    assert_equal '2', l.shift
    assert_equal ['2'], l.shift(1)

    assert_equal l, l.unshift('a')
    assert_equal l, l.unshift('b', 'c')
    assert_equal ['b', 'c', 'a'], l.values

    assert_equal l, l.replace(['x'])
    assert_equal ['x'], l.values

    assert_equal l, l.clear
    assert_equal [], l.values


    # left unimplemented

    assert_raises NotImplementedError do
      l.insert(0, 1)
    end

    assert_raises NotImplementedError do
      l.delete_at(0)
    end

    assert_raises NotImplementedError do
      l.delete_if{true}
    end
      
    assert_raises NotImplementedError do
      l.fill([])
    end

    assert_raises NotImplementedError do
      l.keep_if{true}
    end
    
  end

  def test_delegation
    l = Store.init_list(random_key, ['a', 'b', 'c', 'd', 'e', 'f'])

    assert_equal ['ax', 'bx', 'cx', 'dx', 'ex', 'fx'], l.map{|x| x + 'x'}
    assert_equal ['f', 'e', 'd', 'c', 'b', 'a'], l.reverse

  end

  def test_stringification
    l = Store.init_set(random_key)
    l << 14
    assert l.include?('14')
    assert l.include?(14)
    assert_equal ['14'], l.values
    assert l.delete(14)
    assert_equal( [], l.to_a )
  end


end
