# thread-local (technically fiber-local) indexer
# used to aggregate bulk callbacks across models
module Openkick
  class Indexer
    include Helpers
    attr_reader :queued_items

    def initialize
      @queued_items = []
    end

    def queue(items)
      @queued_items.concat(items)
      perform unless callbacks_value == :bulk
    end

    def perform
      items = @queued_items
      @queued_items = []

      return if items.empty?

      response = Openkick.client.bulk(body: items)
      if response['errors']
        # NOTE: delete does not set error when item not found
        first_with_error = response['items'].map do |item|
          item['index'] || item['delete'] || item['update']
        end.find { |item| item['error'] }
        raise ImportError, "#{first_with_error['error']} on item with id '#{first_with_error['_id']}'"
      end

      # maybe return response in future
      nil
    end
  end
end
