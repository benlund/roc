require File.join(File.dirname(__FILE__), 'roc_test')

class EvalTest < ROCTest

  def test_eval

    Store.enable_eval

    k = random_key

    assert_nil (Store.call :eval, "return redis('get', '#{k}')", 0)
    Store.call :set, k, 'in now'
    assert_equal 'in now', (Store.call :eval, "return redis('get', '#{k}')", 0)

    assert_equal 'in now', (Store.call :eval, "return redis('get', KEYS[1])", 1, k)

  end

  def test_data_types

    str = Store.init_string(random_key, 'str content')
    lst = Store.init_list(random_key, ['a', 'c', 'e', 'b', 'd'])
    s = Store.init_set(random_key, [1,3,4])
    ss = Store.init_sorted_set(random_key, [[1, 'z'], [3, 'd'], [3.1, 'c']])
    hsh = Store.init_hash(random_key, {'foo' => 'bar', 'bar' => 'baz'})

    Store.enable_eval

    assert_equal str.value, Store.call(:eval, "return redis('get', KEYS[1])", 1, str.key)
    assert_equal lst.values, Store.call(:eval, "return redis('lrange', KEYS[1], 0, -1)", 1, lst.key)
    assert_equal s.values.sort, Store.call(:eval, "return redis('smembers', KEYS[1])", 1, s.key).sort
    assert_equal ss.values, Store.call(:eval, "return redis('zrange', KEYS[1], 0, -1)", 1, ss.key)
    assert_equal ss.values(:with_scores => true), Store.call(:eval, "return redis('zrange', KEYS[1], 0, -1, 'WITHSCORES')", 1, ss.key)
    assert_equal hsh.hmget('foo', 'bar'), Store.call(:eval, "return redis('hmget', KEYS[1], ARGV[1], ARGV[2])", 1, hsh.key, 'foo', 'bar')

  end

end
