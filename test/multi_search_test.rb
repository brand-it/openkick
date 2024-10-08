require_relative 'test_helper'

class MultiSearchTest < Minitest::Test
  def test_basic
    store_names ['Product A']
    store_names ['Store A'], Store
    products = Product.search('*')
    stores = Store.search('*')
    Openkick.multi_search([products, stores])

    assert_equal ['Product A'], products.map(&:name)
    assert_equal ['Store A'], stores.map(&:name)
  end

  def test_methods
    result = Product.search('*')
    query = Product.search('*')

    assert_empty(result.methods - query.methods)
  end

  def test_error
    store_names ['Product A']
    products = Product.search('*')
    stores = Store.search('*', order: [:bad_field])
    Openkick.multi_search([products, stores])

    assert !products.error
    assert stores.error
  end

  def test_misspellings_below_unmet
    store_names %w[abc abd aee]
    products = Product.search('abc', misspellings: { below: 5 })
    Openkick.multi_search([products])

    assert_equal %w[abc abd], products.map(&:name)
  end

  def test_misspellings_below_error
    products = Product.search('abc', order: [:bad_field], misspellings: { below: 1 })
    Openkick.multi_search([products])

    assert products.error
  end

  def test_query_error
    products = Product.search('*', order: { bad_field: :asc })
    Openkick.multi_search([products])

    assert products.error
    error = assert_raises(Openkick::Error) { products.results }
    assert_equal 'Query error - use the error method to view it', error.message
  end
end
