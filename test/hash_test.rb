require File.join(File.dirname(__FILE__), 'roc_test')

class HashTest < ROCTest

  def test_rw

    h = Store.init_hash(random_key)

    assert(h['foo'] = 'bar')
    assert(h['bar'] = 'baz')
    assert_equal 'bar', h['foo']
    assert h.has_key?('bar')
    assert !h.has_key?('baz')

    assert_equal ['bar', 'foo'], h.keys.sort
    assert_equal ['bar', 'baz'], h.values.sort

    assert_equal( {'foo' => 'bar', 'bar' => 'baz'}, h.getall )
    assert_equal 2, h.size

    assert h.hdel('bar')
    assert !h.hdel('bar')
    assert_equal ['foo'], h.keys.sort
    assert_equal ['bar'], h.values.sort
    assert_nil h['bar']
    assert_equal 1, h.size

    h['count'] = 5
    h.increment('count')
    assert_equal 6, h['count'].to_i
    h.decrement('count', 2)
    assert_equal 4, h['count'].to_i

    assert h.mset('decaf', 'coffee', 'caffinated', 'tea')
    assert_equal( {'foo' => 'bar', 'count' => '4', 'decaf' => 'coffee', 'caffinated' => 'tea'}, h.getall )

    assert !h.setnx('decaf', 'tea')
    assert_equal( {'foo' => 'bar', 'count' => '4', 'decaf' => 'coffee', 'caffinated' => 'tea'}, h.getall )
    assert h.setnx('brewed', 'tea')
    assert_equal( {'foo' => 'bar', 'count' => '4', 'decaf' => 'coffee', 'caffinated' => 'tea', 'brewed' => 'tea'}, h.getall )

  end

  def test_shortcuts
    h = Store.init_hash(random_key)
    assert h.empty?
    h.merge!({'count' => 4, 'foo' => 'bar'})
    assert_equal ['4', 'bar'], h.values_at('count', 'foo')
    assert h.has_value?('bar')
    assert !h.has_value?('foo')
    assert_equal 'bar', h.delete('foo')
    assert_nil h.delete('foo')
    assert_raises NotImplementedError do
      h.shift
    end
    assert_raises NotImplementedError do
      h.replace('bar' => 'baz')
    end
    assert_raises NotImplementedError do
      h.delete_if{true}
    end
  end

  def test_delegation

  end

end
