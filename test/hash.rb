require 'test/roc_test'

class HashTest < ROCTest

  def test_rw

    h = collection.init_hash(random_key)

    h['foo'] = 'bar'
    h['bar'] = 'baz'
    assert_equal 'bar', h['foo']
    assert h.has_key?('bar')
    assert !h.has_key?('baz')

    assert_equal ['bar', 'foo'], h.keys.sort
    assert_equal ['bar', 'baz'], h.values.sort
    
    assert_equal 2, h.size

    h.delete('bar')
    assert_equal ['foo'], h.keys.sort
    assert_equal ['bar'], h.values.sort
    assert_nil h['bar']
    assert_equal 1, h.size

    h['count'] = 5
    h.increment('count')
    assert_equal 6, h['count'].to_i
    h.decrement('count', 2)
    assert_equal 4, h['count'].to_i

  end

  def test_delegation

  end

end
