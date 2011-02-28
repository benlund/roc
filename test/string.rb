require 'test/roc_test'

class StringTest < ROCTest

  def test_rw
    str = collection.init_string(random_key)
    assert_equal '', str.to_s
    str << 'a'
    str << 'b'
    assert_equal 'ab', str.value
    str << 'inside'
    str << 'c'
    assert_equal 'inside', str.substring(2, 7)
  end

  def test_emulation
    str = collection.init_string(random_key)
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
    str = collection.init_string(random_key)
    assert_equal 'x', (str + 'x')
    str.value = "123"
    assert_equal "321", str.reverse
    str << 'x32'
    assert_equal 3, str.match(/(\d+)/)[1].size
  end

end
