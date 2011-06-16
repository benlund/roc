require File.join(File.dirname(__FILE__), 'roc_test')

class InitializationTest < ROCTest

  def test_00_global
    k = random_key

    assert_raises ArgumentError, do
      ROC::String.new(k)
    end

    ROC::Base.storage = Store

    str = ROC::String.new(k, 'sdfdsfdsfds')
    assert_equal str.value, Store.init_string(k).value
  end

  def test_01_subclass
    k = random_key

    ROC::String.storage = ROC::Store::TransientStore.new

    str = ROC::String.new(k, 'j;jkljklkljklj')

    assert_not_equal str.value, Store.init_string(k).value

    ROC::String.storage = Store

    assert_equal str.value, Store.init_string(k).value
  end

  def test_02_instance
    k = random_key

    str = ROC::String.new(k, ROC::Store::TransientStore.new, '043euudfio')

    assert_not_equal str.value, Store.init_string(k).value

    str.storage = Store

    assert_equal str.value, Store.init_string(k).value
  end

end
