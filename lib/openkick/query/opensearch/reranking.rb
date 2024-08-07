# frozen_string_literal: true

module Openkick
  class Query
    module Opensearch
      class Reranking
        def initialize(term, payload:, options:)
          @term = term
          @payload = payload
          @search_pipeline = options.dig(:rerank, :search_pipeline)
          @rerank = options.key?(:rerank)
          return unless @search_pipeline.to_s == '' && Openkick.server_below?('2.13')

          raise 'search_pipline is required when using opensearch version 2.13 or older'
        end

        def self.call(...)
          new(...).call
        end

        def call
          return unless Openkick.opensearch? && @rerank

          @payload[:ext] = {
            rerank: {
              query_context: {
                query_text: @term
              }
            }
          }
        end
      end
    end
  end
end
