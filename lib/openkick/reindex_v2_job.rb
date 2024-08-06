module Openkick
  class ReindexV2Job < ActiveJob::Base
    queue_as { Openkick.queue_name }

    def perform(class_name, id, method_name = nil, routing: nil, index_name: nil)
      model = Openkick.load_model(class_name, allow_child: true)
      index = model.openkick_index(name: index_name)
      # use should_index? to decide whether to index (not default scope)
      # just like saving inline
      # could use Openkick.scope() in future
      # but keep for now for backwards compatibility
      model = model.unscoped if model.respond_to?(:unscoped)
      items = [{id: id, routing: routing}]
      RecordIndexer.new(index).reindex_items(model, items, method_name: method_name, single: true)
    end
  end
end
