module Openkick
  class ProcessQueueJob < ActiveJob::Base
    queue_as { Openkick.queue_name }

    def perform(class_name:, index_name: nil, inline: false)
      model = Openkick.load_model(class_name)
      index = model.openkick_index(name: index_name)
      limit = model.openkick_options[:batch_size] || 1000

      loop do
        record_ids = index.reindex_queue.reserve(limit:)
        if record_ids.any?
          batch_options = {
            class_name:,
            record_ids: record_ids.uniq,
            index_name:
          }

          if inline
            # use new.perform to avoid excessive logging
            Openkick::ProcessBatchJob.new.perform(**batch_options)
          else
            Openkick::ProcessBatchJob.perform_later(**batch_options)
          end

          # TODO: when moving to reliable queuing, mark as complete
        end
        break unless record_ids.size == limit
      end
    end
  end
end
