require File.join(File.dirname(__FILE__), 'roc_test')

class TransactionsTest < ROCTest

  def test_multi
    str = Store.init_string(random_key, 'hi there')

    Store.multi do
      str.value = 'bye there'
    end
    assert_equal 'bye there', str.to_s      

    Store.multi
    str.value = 'why there'
    Store.discard
    assert_equal 'bye there', str.to_s

    list = Store.init_list(random_key, ['a', 'z'])
    assert_equal ['bye there', ['a', 'z']], Store.multi{str.value; list.values}
  end

  def test_watch
    ## erm, todo
  end

end
