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
    assert_equal 12, str.length
    str << "∂ƒ"
    assert_equal 17, str.length
  end

  def test_aliases
    str = Store.init_string(random_key, 'dsfdsfsd')

    assert_equal str.value, str.to_s
    assert_equal str.value, str.to_string
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

  def test_emulation
    return
    str = Store.init_string(random_key)
    str.value = "something"
    assert_equal "something"[0], str[0]
    assert_equal "something"[1..3], str[1..3]
    assert_equal "something"[1...5], str[1...5]
    assert_equal "something".slice(3, 2), str.slice(3, 2)
    assert_equal "something".slice(-1), str.slice(-1)
    assert_equal "something".slice(4, -1), str.slice(4, -1) ## what is this supposed to do?
    #assert_equal "something".slice(0, -1), str.slice(0, -1) ##@@ fails - fixme

    # emulation -> delgaton
    assert_equal "something"[/m|e/], str[/m|e/]
    assert_equal "something".slice(/(me?)/, 0), str.slice(/(me?)/, 0)
    assert_equal "something".slice(/(me?)/, 1), str.slice(/(me?)/, 1)
  end

  def test_delegation
    return
    str = Store.init_string(random_key)
    assert_equal 'x', (str + 'x')
    str.value = "123"
    assert_equal "321", str.reverse
    str << 'x32'
    assert_equal 3, str.match(/(\d+)/)[1].size
  end

end
