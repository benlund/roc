# encoding: UTF-8
require File.join(File.dirname(__FILE__), 'roc_test')

class StringTest < ROCTest

  def test_find
    k = random_key
    obj = Store.find(k)
    assert_nil obj

    Store.init_string(k, 'dsdfsd')
    obj = Store.find(k)
    assert_equal ROC::String, obj.class
  end

  def test_rw
    str = Store.init_string(random_key)

    # empty
    assert_nil str.value
    assert_equal '', str.to_s

    # set and get
    str.value = 'a'
    assert_equal 'a', str.value

    # setnx
    str.setnx('blah')
    assert_equal 'a', str.value
    new_str = Store.init_string(random_key)
    new_str.setnx('blah')
    assert_equal 'blah', new_str.value

    #getset
    assert_equal 'blah', new_str.getset('blahblah')
    assert_equal 'blahblah', new_str.value

    # append
    str << 'b'
    assert_equal 'ab', str.value

    # getrange and setrange    
    str << 'inside'
    str << 'c'
    assert_equal 'inside', str.substring(2, 7)
    assert_equal 'ec', str.substring(-2, -1)
    assert_nil str.substring(100, 101)
    str.splice(2, 'up')
    assert_equal 'abupsidec', str.value
    str.splice(10, 'x')
    assert_equal "abupsidec\u0000x", str.value

    # getbit and setbit
    assert_equal 0, str.getbit(3)
    assert_equal 0, str.setbit(3, 1)
    assert_equal 1, str.getbit(3)
    assert_equal 0, str.setbit(89, 0)
    assert_equal "qbupsidec\u0000x\u0000", str.value

    # length
    assert_equal 12, str.bytesize
    str << "∂ƒ"
    assert_equal 17, str.bytesize
  end

  def test_setex
    str = Store.init_string(random_key)
    str.setex(1, 'blah')
    assert(str.ttl > 0)

    sleep 1
    assert_equal 'blah', str.value

    sleep 1
    assert_nil str.value

    str.setex(1, 'blah')
    assert(str.ttl > 0)

    str.set('blah2')
    assert_equal -1, str.ttl
  end

  def test_shortcut
    #get/setbyte

    raw_str = 'quick brown fox!´®†∑∂ƒ©'
    str = Store.init_string(random_key, raw_str)

    # go one over to test nil
    (0..raw_str.bytesize).each do |i|
      assert_equal raw_str.getbyte(i), str.getbyte(i)
    end

    assert_equal raw_str.setbyte(6, 98), str.setbyte(6, 98)
    assert_equal raw_str, str.to_s

  end

  def test_delegation
    str = Store.init_string(random_key, 'x')
    assert_equal 'xx', (str + 'x')
    str.value = "123"
    assert_equal "321", str.reverse
    str << 'x32'
    assert_equal 3, str.match(/(\d+)/)[1].size

    raw_str = 'quick brown fox!´®†∑∂ƒ©'
    str = Store.init_string(random_key, raw_str)

    assert_equal raw_str[4], str[4]
    assert_equal raw_str[4, 3], str[4, 3]
    assert_equal raw_str[4..10], str[4..10]
    assert_equal raw_str[4...10], str[4...10]
    assert_equal raw_str[raw_str.length - 4], str[raw_str.length - 4]
    assert_equal raw_str[raw_str.length - 4, 3], str[raw_str.length - 4, 3],
  end

end
