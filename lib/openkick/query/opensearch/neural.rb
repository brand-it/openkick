# frozen_string_literal: true

module Openkick
  class Query
    module Opensearch
      class Neural
        DEFAULTS = {}.freeze

        def initialize(term, queries:, options:)
          @term = term
          @queries = queries
          @neural = options[:neural]
          @neural = @neural.to_h { |n| [n, {}] } if @neural.is_a?(Array)
        end

        def self.call(...)
          new(...).call
        end

        def call
          return if term_blank? || !@neural.is_a?(Hash)

          @neural.transform_values do |attributes|
            attributes[:query_text] ||= @term
            attributes[:k] ||= 5
          end
          @queries << { neural: @neural }
        end

        private

        def term_blank?
          @term.to_s == '' || @term == '*'
        end
      end
    end
  end
end
