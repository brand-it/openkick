# frozen_string_literal: true

module Openkick
  class Query
    module Opensearch
      class NeuralSparse
        DEFAULTS = {}.freeze

        def initialize(term, queries:, options:)
          @term = term
          @queries = queries
          @neural_sparse = options[:neural_sparse]
          @neural_sparse = @neural_sparse.to_h { |n| [n, {}] } if @neural_sparse.is_a?(Array)
        end

        def self.call(...)
          new(...).call
        end

        def call
          return if term_blank? || !@neural_sparse.is_a?(Hash)

          @neural_sparse.transform_values do |attributes|
            attributes[:query_text] ||= @term
          end
          @queries << { neural_sparse: @neural_sparse }
        end

        private

        def term_blank?
          @term.to_s == '' || @term == '*'
        end
      end
    end
  end
end
