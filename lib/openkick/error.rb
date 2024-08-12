# frozen_string_literal: true

module Openkick
  class Error < StandardError; end
  class MissingIndexError < Error; end

  class UnsupportedVersionError < Error
    def message
      'This version of Openkick requires Elasticsearch 7+ or OpenSearch 1+'
    end
  end

  class InvalidQueryError < Error; end
  class DangerousOperation < Error; end
  class ImportError < Error; end
end
