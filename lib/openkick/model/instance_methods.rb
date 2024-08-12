# frozen_string_literal: true

module Openkick
  module Model
    module InstanceMethods
      def reindex(method_name = nil, mode: nil, refresh: false)
        self.class.openkick_index.reindex([self], method_name:, mode:, refresh:, single: true)
      end

      def similar(**options)
        self.class.openkick_index.similar_record(self, **options)
      end

      def search_data
        data = respond_to?(:to_hash) ? to_hash : serializable_hash
        data.delete('id')
        data.delete('_id')
        data.delete('_type')
        data
      end

      def should_index?
        true
      end
    end
  end
end
