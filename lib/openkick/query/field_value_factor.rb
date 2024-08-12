# frozen_string_literal: true

module Openkick
  class Query
    class FieldValueFactor
      DEFAULTS = {
        factor: 0.001
      }.freeze
      def initialize(field_value_factor, custom_filters:)
        @custom_filters = custom_filters
        @field_value_factor = Array.wrap(field_value_factor)
      end

      def self.call(...)
        new(...).call
      end

      def call
        return if @field_value_factor.empty?

        @field_value_factor.each do |factor|
          weight = factor.delete(:weight) || 1
          @custom_filters << {
            weight:,
            field_value_factor: DEFAULTS.merge(factor),
            _name: "#{factor[:field]}_function"
          }
        end
      end
    end
  end
end
