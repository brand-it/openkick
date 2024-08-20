# frozen_string_literal: true

module Openkick
  module Model
    module InstanceMethods
      def self.included(base)
        unless base.method_defined?(:reindex)
          base.define_method(:reindex) do |method_name = nil, mode: nil, refresh: false|
            self.class.openkick_index.reindex([self], method_name:, mode:, refresh:, single: true)
          end
        end

        unless base.method_defined?(:similar)
          base.define_method(:similar) do |**options|
            self.class.openkick_index.similar_record(self, **options)
          end
        end

        unless base.method_defined?(:search_data)
          base.define_method(:search_data) do
            data = respond_to?(:to_hash) ? to_hash : serializable_hash
            data.delete('id')
            data.delete('_id')
            data.delete('_type')
            data
          end
        end

        unless base.method_defined?(:should_index?)
          base.define_method(:should_index?) do
            true
          end
        end
      end
    end
  end
end
