# frozen_string_literal: true

require_relative 'test_helper'

class AfterCommitReindexTest < Minitest::Test
  def setup
    super
    store [
      {
        name: 'Product Show',
        latitude: 37.7833, longitude: 12.4167,
        store_id: 1, in_stock: true, color: 'blue',
        price: 21, created_at: 2.days.ago
      },
      {
        name: 'Product Hide',
        latitude: 29.4167, longitude: -98.5000,
        store_id: 2, in_stock: false, color: 'green',
        price: 25, created_at: 2.days.from_now
      },
      {
        name: 'Product B',
        latitude: 43.9333, longitude: -122.4667,
        store_id: 2, in_stock: false, color: 'red',
        price: 5, created_at: Time.now
      },
      {
        name: 'Foo',
        latitude: 43.9333, longitude: 12.4667,
        store_id: 3, in_stock: false, color: 'yellow',
        price: 15, created_at: Time.now
      }
    ]

    store [
      { id: 1, name: 'Store A' },
      { id: 2, name: 'Store B' },
      { id: 3, name: 'Store C' }
    ], Store
  end

  def test_product_reindex
    Product.first.update_columns(color: 'silver')
    Store.first.update!(name: 'New Name')

    Product.openkick_index.refresh

    store_names = Product.search('*', select: [:store_name]).hits.map { _1['_source']['store_name'] }.sort
    product_colors = Product.search('*', select: [:color]).hits.map { _1['_source']['color'] }.sort

    assert_equal ['New Name', 'Store B', 'Store B', 'Store C'], store_names
    # Make sure the Store update only updates store attributes
    assert_equal %w[blue green red yellow], product_colors
  end
end
