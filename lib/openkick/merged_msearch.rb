module Openkick
  class MergedMsearch
    extend Dry::Initializer

    param :queries, ::Dry.Types::Coercible::Array.of(::Dry.Types.Instance(::Searchkick::Relation))
    option :limit, ::Dry.Types::Coercible::Integer.optional, optional: true
    option :offset, ::Dry.Types::Coercible::Integer.optional, optional: true

    # Performs a multi search using the specified queries.
    #
    # This method updates the query limits if a limit is specified, and then performs a multi-search using the queries.
    # The results are wrapped in a `Results` object and returned.
    #
    # @return [WmSearchkick::MergedMsearch::Results] The results of the multi search.
    def self.search(...)
      new(...).search
    end

    def initialize(queries, limit: 25, offset: 0)
      @queries = verify_queries(Array.wrap(queries))
      @limit = limit
      @offset = offset
    end

    def search
      Openkick::MergedMsearch::Results.new(execute_queries)
    end

    private

    def execute_queries
      per_page = limit.to_i
      query_offset = offset.to_i
      queries.map do |query|
        query.offset!(query_offset)
        query.per_page!(per_page)
        per_page = (per_page - query.send(:hits).size).clamp(0, Float::INFINITY)
        query_offset = (query_offset - query.total_count).clamp(0, Float::INFINITY)
        query
      end
    end

    def verify_queries(queries)
      return queries if queries.all? { _1.is_a?(::Searchkick::Relation) }

      raise TypeError, 'All elements must be of type Openkick::Relation'
    end
  end
end
