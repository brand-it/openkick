module Openkick
  class ProcessBatchJob < ActiveJob::Base
    include Helpers
    queue_as { Openkick.queue_name }

    def perform(class_name:, record_ids:, index_name: nil)
      model = Openkick.load_model(class_name)
      index = model.openkick_index(name: index_name)

      items =
        record_ids.map do |r|
          parts = r.split(/(?<!\|)\|(?!\|)/, 2)
                   .map { |v| v.gsub('||', '|') }
          { id: parts[0], routing: parts[1] }
        end

      relation = scope(model)
      RecordIndexer.new(index).reindex_items(relation, items, method_name: nil)
    end
  end
end
