require File.join(File.dirname(__FILE__), 'roc_test')

class EvalTest < ROCTest

  def test_eval

    Store.enable_eval

    k = random_key

    assert_nil (Store.call :eval, "return redis.call('get', '#{k}')", 0)
    Store.call :set, k, 'in now'
    assert_equal 'in now', (Store.call :eval, "return redis.call('get', '#{k}')", 0)

    assert_equal 'in now', (Store.call :eval, "return redis.call('get', KEYS[1])", 1, k)
  end

  def test_data_types

    str = Store.init_string(random_key, 'str content')
    lst = Store.init_list(random_key, ['a', 'c', 'e', 'b', 'd'])
    s = Store.init_set(random_key, [1,3,4])
    ss = Store.init_sorted_set(random_key, [[1, 'z'], [3, 'd'], [3.1, 'c']])
    hsh = Store.init_hash(random_key, {'foo' => 'bar', 'bar' => 'baz'})

    Store.enable_eval

    assert_equal str.value, str.eval("return redis.call('get', KEYS[1])")
    assert_equal lst.values, lst.eval("return redis.call('lrange', KEYS[1], 0, -1)")
    assert_equal s.values.sort, s.eval("return redis.call('smembers', KEYS[1])").sort
    assert_equal ss.values, ss.eval("return redis.call('zrange', KEYS[1], 0, -1)")
    assert_equal ss.values(:with_scores => true), ss.eval("return redis.call('zrange', KEYS[1], 0, -1, 'WITHSCORES')")
    assert_equal hsh.hmget('foo', 'bar'), hsh.eval("return redis.call('hmget', KEYS[1], ARGV[1], ARGV[2])", 'foo', 'bar')

  end

end
