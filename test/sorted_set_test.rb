require File.join(File.dirname(__FILE__), 'roc_test')

class SortedSetTest < ROCTest

  def test_find
    k = random_key
    obj = Store.find(k)
    assert_nil obj

    Store.init_sorted_set(k, [[1, 'dsdfsd']])
    obj = Store.find(k)
    assert_equal ROC::SortedSet, obj.class
    assert_equal ['dsdfsd'], obj.values
  end

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

    #range and revrange
    assert_equal ['a', 'w'], s.range(1, 2)
    assert_equal ['z', 'a', 'w'], s.range(0, -2)
    assert_equal ['w', 'y'], s.range(-2, -1)
    assert_equal ['z', 'a', 'w', 'y'], s.range(-4, -1)
    assert_equal ['z', 'a', 'w', 'y'], s.range(-5, -1)
    assert_equal ['w', 'a'], s.revrange(1, 2)
    assert_equal ['y', 'w', 'a', 'z'], s.revrange(0, -1)

    #z(rev)rangebyscore, zcount

    assert_equal [], s.rangebyscore(100, 200)
    assert_equal 0, s.count(100, 200)

    assert_equal ['w', 'y'], s.rangebyscore(6, 7)
    assert_equal ['y', 'w'], s.revrangebyscore(7, 6)
    assert_equal 2, s.count(6, 7)

    assert_equal ['z', 'a', 'w', 'y'], s.rangebyscore('-inf','+inf')
    assert_equal ['y', 'w', 'a', 'z'], s.revrangebyscore('+inf','-inf')
    assert_equal 4, s.count('-inf','+inf')

    assert_equal ['a', 'w', 'y'], s.rangebyscore('(1', '6')
    assert_equal 3, s.count('(1', '6')

    assert_equal ['a'], s.rangebyscore('(1', '(6')
    assert_equal 1, s.count('(1', '(6')

    assert_equal ['a', 'w'], s.rangebyscore('(1', '6', :limit => [0, 2])
    assert_equal ['y', 'w'], s.revrangebyscore('+inf','-inf', :limit => [0, 2])
    assert_equal ['z', '1', 'a', '2', 'w', '6', 'y', '6'], s.rangebyscore('-inf','+inf', :with_scores => true)
    assert_equal ['a', '2', 'w', '6'], s.rangebyscore('-inf','+inf', :with_scores => true, :limit => [1, 2])

    #zrem

    assert s.rem('z')
    assert !s.rem('z')
    assert_equal 3, s.size

    #zrank, zrevrank

    assert_nil s.rank('z')
    assert_nil s.revrank('z')
    assert_equal 1, s.rank('w')
    assert_equal 1, s.revrank('w')
    assert_nil Store.init_sorted_set(random_key).rank('x')

    #zscore
    assert_nil s.score('z')
    assert_equal '6', s.score('w')
    assert_nil Store.init_sorted_set(random_key).score('x')

    #zremrangeby*
    s << [-1, 'x']
    s << [10, 'xx']
    s << [11, 'xxx']

    assert_equal 1, s.remrangebyscore('-inf', -1)
    assert_equal 0, s.remrangebyscore('(11', '+inf')
    assert_equal 2, s.remrangebyscore('10', '+inf')

    s << [3, 'b']
    s << [4, 'c']

    assert_equal 2, s.remrangebyrank(1, 2)

    assert_equal '7', s.incrby(1, 'w')
    assert_equal ['a', 'y', 'w'], s.values   
    assert_equal '6', s.incrby(-1, 'w')

    #set ops

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

    #multiple

    yos = Store.init_sorted_set(random_key, [{:value => 'z', :score => 1}])
    us.set_as_union_of(s, os, yos)
    is.set_as_intersect_of(s, os, yos)
    assert_equal [ 'a', 'z', 'y', 'w'], us.values
    assert_equal [], is.values
    yos << [2, 'w']
    is.set_as_intersect_of(s, os, yos)
    assert_equal ['w', '15'], is.values(:with_scores => true)

    ## sort
    
    assert_equal ['a', 'w', 'y'], s.sort(:order => 'alpha')
    assert_equal ['y', 'w', 'a'], s.sort(:order => 'alpha desc')
    assert_equal ['y', 'w'], s.sort(:order => 'alpha desc', :limit => [0, 2])
    

    ## empty it - check for regression

    s.rem('a')
    s.rem('y')
    s.rem('w')
    assert_nil s.last
    assert_equal [],  s.range(-1, 0)

    #sort numbers

    s << [0, '1.1']
    s << [0, '0.2']
    s << [0, '47']

    assert_equal ['0.2', '1.1', '47'], s.sort
    assert_equal ['47', '1.1', '0.2'], s.sort(:order => 'desc')

    sl = Store.init_list(random_key)

    s.sort(:store => sl)
    assert_equal ['0.2', '1.1', '47'], sl.values
  end

  def test_shortcuts

    s = Store.init_sorted_set(random_key)
    s << [-2, 'a']
    s << [0, 'b']
    s << [200, 'c']
    s << [200, 'd']
    s << [201, 'e']
    s << [3000, 'f']

    assert_equal 'a', s.first
    assert_equal 'f', s.last

    assert_equal 'b', s[1]
    assert_equal ['c', 'd', 'e'], s[2..4]
    assert_equal ['c', 'd'], s[2...4]

    assert s.include?('c')
    assert !s.include?('x')

    assert_equal 3, s.index('d')
    assert_nil s.index('x')

    assert_equal ['f', 'e', 'd', 'c', 'b', 'a'], s.reverse

  end

  def test_helpers
    s = Store.init_sorted_set(random_key)
    s << [2, 'a']
    s << [3, 'z']
    assert_equal '4', s.increment('z')
    assert_equal '4', s.score('z')
    assert_equal '1', s.decrement('a')
    assert_equal '1', s.score('a')
    assert_equal({'a' => '1', 'z' => '4'}, s.to_hash)
  end

  def test_mask

    # implemented

    s = Store.init_sorted_set(random_key, [['2','1'], ['3', '2']])
    assert_equal '1', s.delete('1')
    assert_equal ['2'], s.values

    assert_equal s, (s << {:score => '0', :value => '1'})
    assert_equal ['1', '2'], s.values
    
    assert_equal s, s.push(['12', '3'], ['100', '4'])
    assert_equal ['1', '2', '3', '4'], s.values

    assert_equal s, s.replace([['1', 'x']])
    assert_equal ['x'], s.values

    assert_equal s, s.clear
    assert_equal [], s.values

    # left unimplemented

    assert_raises NotImplementedError do
      s.pop
    end

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

  def test_delegation
    s = Store.init_sorted_set(random_key)
    s << [-2, 'a']
    s << [0, 'b']
    s << [200, 'c']
    s << [200, 'd']
    s << [201, 'e']
    s << [3000, 'f']

    assert_equal ['ax', 'bx', 'cx', 'dx', 'ex', 'fx'], s.map{|x| x + 'x'}
  end

  def test_stringification
    s = Store.init_sorted_set(random_key)
    s << [2, 14]
    assert s.include?('14')
    assert_equal '2', s.score(14)
    assert_equal '2', s.score('14')
    assert_equal 0, s.rank(14)
    assert_equal 0, s.rank('14')
    assert_equal ['14'], s.values
    assert s.rem(14)
    assert_equal [], s.values
  end

end
