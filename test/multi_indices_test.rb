require_relative 'test_helper'

class MultiIndicesTest < Minitest::Test
  def setup
    super
    setup_speaker
  end

  def test_basic
    store_names ['Product A']
    store_names ['Product B'], Speaker

    assert_search_multi 'product', ['Product A', 'Product B']
  end

  def test_index_name
    store_names ['Product A']

    assert_equal ['Product A'], Product.search('product', index_name: Product.openkick_index.name).map(&:name)
    assert_equal ['Product A'], Product.search('product', index_name: Product).map(&:name)

    Speaker.openkick_index.refresh

    assert_empty Product.search('product', index_name: Speaker.openkick_index.name, conversions: false).map(&:name)
  end

  def test_models_and_index_name
    store_names ['Product A']
    store_names ['Product B'], Speaker

    assert_equal ['Product A'],
                 Openkick.search('product', models: [Product, Store],
                                            index_name: Product.openkick_index.name).map(&:name)
    error = assert_raises(Openkick::Error) do
      Openkick.search('product', models: [Product, Store], index_name: Speaker.openkick_index.name).map(&:name)
    end
    assert_includes error.message, 'Unknown model'
    # legacy
    assert_equal ['Product A'], Openkick.search('product', index_name: [Product, Store]).map(&:name)
  end

  def test_model_with_another_model
    error = assert_raises(ArgumentError) do
      Product.search(models: [Store])
    end
    assert_includes error.message, 'Use Openkick.search'
  end

  def test_model_with_another_model_in_index_name
    error = assert_raises(ArgumentError) do
      # legacy protection
      Product.search(index_name: [Store, 'another'])
    end
    assert_includes error.message, 'Use Openkick.search'
  end

  def test_no_models_or_index_name
    store_names ['Product A']

    error = assert_raises(Openkick::Error) do
      Openkick.search('product').results
    end
    assert_includes error.message, 'Unknown model'
  end

  def test_no_models_or_index_name_load_false
    store_names ['Product A']
    Openkick.search('product', load: false).results
  end

  private

  def assert_search_multi(term, expected, options = {})
    options[:models] = [Product, Speaker]
    options[:fields] = [:name]

    assert_search(term, expected, options, Openkick)
  end
end
