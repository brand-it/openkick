require_relative 'test_helper'

class RoutingTest < Minitest::Test
  def test_query
    query = Store.search('Dollar Tree', routing: 'Dollar Tree')

    assert_equal 'Dollar Tree', query.params[:routing]
  end

  def test_mappings
    mappings = Store.openkick_index.index_options[:mappings]

    assert_equal({ required: true }, mappings[:_routing])
  end

  def test_correct_node
    store_names ['Dollar Tree'], Store

    assert_search '*', ['Dollar Tree'], { routing: 'Dollar Tree' }, Store
  end

  def test_incorrect_node
    store_names ['Dollar Tree'], Store

    assert_search '*', ['Dollar Tree'], { routing: 'Boom' }, Store
  end

  def test_async
    with_options({ routing: true, callbacks: :async }, Song) do
      store_names ['Dollar Tree'], Song
      Song.destroy_all
    end
  end

  def test_queue
    with_options({ routing: true, callbacks: :queue }, Song) do
      store_names ['Dollar Tree'], Song
      Song.destroy_all
      Openkick::ProcessQueueJob.perform_later(class_name: 'Song')
    end
  end
end
