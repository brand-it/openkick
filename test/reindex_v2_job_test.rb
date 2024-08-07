require_relative 'test_helper'

class ReindexV2JobTest < Minitest::Test
  def test_create
    product = Openkick.callbacks(false) { Product.create!(name: 'Boom') }
    Product.openkick_index.refresh

    assert_search '*', []
    Openkick::ReindexV2Job.perform_now('Product', product.id.to_s)
    Product.openkick_index.refresh

    assert_search '*', ['Boom']
  end

  def test_destroy
    product = Openkick.callbacks(false) { Product.create!(name: 'Boom') }
    Product.reindex

    assert_search '*', ['Boom']
    Openkick.callbacks(false) { product.destroy }
    Openkick::ReindexV2Job.perform_now('Product', product.id.to_s)
    Product.openkick_index.refresh

    assert_search '*', []
  end
end
