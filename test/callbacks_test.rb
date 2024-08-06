require_relative "test_helper"

class CallbacksTest < Minitest::Test
  def test_false
    Openkick.callbacks(false) do
      store_names ["Product A", "Product B"]
    end
    assert_search "product", []
  end

  def test_bulk
    Openkick.callbacks(:bulk) do
      store_names ["Product A", "Product B"]
    end
    Product.openkick_index.refresh
    assert_search "product", ["Product A", "Product B"]
  end

  def test_queue
    # TODO figure out which earlier test leaves records in index
    Product.reindex

    reindex_queue = Product.openkick_index.reindex_queue
    reindex_queue.clear

    Openkick.callbacks(:queue) do
      store_names ["Product A", "Product B"]
    end
    Product.openkick_index.refresh
    assert_search "product", [], load: false, conversions: false
    assert_equal 2, reindex_queue.length

    perform_enqueued_jobs do
      Openkick::ProcessQueueJob.perform_now(class_name: "Product")
    end
    Product.openkick_index.refresh
    assert_search "product", ["Product A", "Product B"], load: false
    assert_equal 0, reindex_queue.length

    Openkick.callbacks(:queue) do
      Product.where(name: "Product B").destroy_all
      Product.create!(name: "Product C")
    end
    Product.openkick_index.refresh
    assert_search "product", ["Product A", "Product B"], load: false
    assert_equal 2, reindex_queue.length

    perform_enqueued_jobs do
      Openkick::ProcessQueueJob.perform_now(class_name: "Product")
    end
    Product.openkick_index.refresh
    assert_search "product", ["Product A", "Product C"], load: false
    assert_equal 0, reindex_queue.length

    # ensure no error with empty queue
    Openkick::ProcessQueueJob.perform_now(class_name: "Product")
  end

  def test_disable_callbacks
    # make sure callbacks default to on
    assert Openkick.callbacks?

    store_names ["product a"]

    Openkick.disable_callbacks
    assert !Openkick.callbacks?

    store_names ["product b"]
    assert_search "product", ["product a"]

    Openkick.enable_callbacks
    Product.reindex

    assert_search "product", ["product a", "product b"]
  end
end
