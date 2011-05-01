require File.join(File.dirname(__FILE__), 'roc_test')

class SetTest < ROCTest

  def test_find
    k = random_key
    obj = Store.find(k)
    assert_nil obj

    Store.init_set(k, ['dsdfsd'])
    obj = Store.find(k)
    assert_equal ROC::Set, obj.class
    assert_equal ['dsdfsd'], obj.values
  end

  def test_rw
    s = Store.init_set(random_key)
    assert_equal 0, s.size
    assert_equal [], s.values
    assert_equal [], s.to_a

    assert s.add('a')
    assert !s.add('a')
    assert_equal 1, s.size
    assert_equal 'a', s.pop
    assert !s.exists?

    assert s.add('z')
    assert s.include?('z')
    assert !s.include?('zzz')
    
    assert s.add('y')
    assert s.add('w')
    assert ['z','y','w'].include?(s.rand_member)
    assert_equal ['w','y','z'], s.values.sort
    assert_equal 3, s.size

    assert s.rem('z')
    assert_equal ['w','y'], s.values.sort

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

    yos = Store.init_set(random_key, ['a', 'y', 'z'])
    assert_equal ['a', 'w', 'y', 'z'], (s.union(os, yos)).sort
    assert_equal ['y'], s.intersect(os, yos)
    yos.rem('y')
    assert_equal [], s.intersect(os, yos)
    assert_equal [], os.diff(s, yos)
    yos.rem('z')
    assert_equal ['z'], os.diff(s, yos)

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


    ## sort

    assert_equal ['w', 'y', 'z'], u_set.sort(:order => 'alpha')
    assert_equal ['z', 'y', 'w'], u_set.sort(:order => 'alpha desc')
    assert_equal ['z', 'y'], u_set.sort(:order => 'alpha desc', :limit => [0, 2])
    

    ## empty it

    u_set.rem('w')
    u_set.rem('y')
    u_set.rem('z')

    ## regression test
    assert_nil u_set.last

    #sort numbers

    u_set << '1.1'
    u_set << '0.2'
    u_set << '47'

    assert_equal ['0.2', '1.1', '47'], u_set.sort
    assert_equal ['47', '1.1', '0.2'], u_set.sort(:order => 'desc')

    sl = Store.init_list(random_key)

    u_set.sort(:store => sl)
    assert_equal ['0.2', '1.1', '47'], sl.values

  end

  def test_mask

    # implemented

    s = Store.init_set(random_key, ['1','2'])
    assert_equal '1', s.delete('1')
    assert_equal ['2'], s.values

    assert_equal s, (s << '1')
    assert_equal ['1', '2'], s.values.sort
    
    assert_equal s, s.push('3', '4')
    assert_equal ['1', '2', '3', '4'], s.values.sort

    assert ['1', '2', '3', '4'].include?(s.pop)
    random_vals = s.pop(2)
    assert_equal 2, random_vals.size
    assert (random_vals & s.values).empty?

    assert_equal s, s.replace(['x'])
    assert_equal ['x'], s.values

    assert_equal s, s.clear
    assert_equal [], s.values

    # left unimplemented

    assert_raises NotImplementedError do
      s.shift(3)
    end

    assert_raises NotImplementedError do
      s.unshift('3', '4')
    end

    assert_raises NotImplementedError do
      s.delete_at(0)
    end

    assert_raises NotImplementedError do
      s.delete_if{true}
    end

    assert_raises NotImplementedError do
      s.insert(0, 1)
    end

    assert_raises NotImplementedError do
      s.fill([])
    end

    assert_raises NotImplementedError do
      s.keep_if{true}
    end   

  end

  def test_helpers
    s = Store.init_set(random_key, ['1','2'])
    assert_equal({'1' => true, '2' => true}, s.to_hash)
  end

  def test_delegation
    l = Store.init_list(random_key, ['a', 'b', 'c', 'd', 'e', 'f'])

    assert_equal ['a', 'b', 'c', 'd', 'e', 'f'], l.sort

  end

  def test_stringification
    s = Store.init_set(random_key)
    s << 14
    assert s.include?('14')
    assert s.include?(14)
    assert_equal ['14'], s.values
    assert s.delete(14)
    assert_equal( [], s.to_a )
  end

end
