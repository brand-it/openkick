module Openkick
  class MergedMsearch
    class Results
      UNSORTABLE_AGGS = %i[ranges date_ranges date_histogram].freeze
      include Enumerable
      extend Forwardable

      attr_reader :queries

      # For all array methods to records
      def_delegators :records, *Array.instance_methods(false)

      def initialize(queries)
        @queries = queries
      end

      def aggs
        @aggs ||= {}.tap do |aggs|
          queries.each do |query|
            next if query.aggs.nil?

            merge_hash!(aggs, query.aggs)
            sum_and_sort_aggs_buckets_by_doc_count!(aggs)
          end
        end
      end

      def suggestions
        @suggestions ||= queries.flat_map(&:suggestions)
      end

      def errors
        @errors ||= queries.flat_map(&:error).compact
      end

      def hits
        @hits ||= queries.flat_map(&:hits)
      end

      def with_hits(&block)
        queries.each do |query|
          query.with_hits(&block)
        end
      end

      def each
        records.each { yield _1 }
      end

      def total_count
        @total_count ||= queries.sum(&:total_count)
      end

      def current_page
        queries.first.current_page
      end

      def per_page
        queries.sum(&:per_page)
      end
      alias limit_value per_page

      def padding
        queries.first.padding
      end

      def total_pages
        (total_count / per_page.to_f).ceil
      end
      alias num_pages total_pages

      def offset_value
        ((current_page - 1) * per_page) + padding
      end
      alias offset offset_value

      def previous_page
        current_page > 1 ? (current_page - 1) : nil
      end
      alias prev_page previous_page

      def next_page
        current_page < total_pages ? (current_page + 1) : nil
      end

      def first_page?
        previous_page.nil?
      end

      def last_page?
        next_page.nil?
      end

      def out_of_range?
        current_page > total_pages
      end

      private

      # Converts all the query aggs into a single hash
      # and merges the buckets based on the key
      #
      # @return [Hash] - The merged query aggs into a unified hash
      def aggs_options
        @aggs_options ||= queries.each_with_object({}) do |query, aggs|
          query_aggs = query.options[:aggs]
          if query_aggs.is_a?(Array)
            query_aggs = query_aggs.each_with_object({}) do |agg, hash|
              agg.is_a?(Hash) ? hash.merge!(agg) : hash[agg] = {}
            end
          end
          aggs.merge!(query_aggs)
        end
      end

      # Merges to hash together as a single hash.
      # Also sum the values if they are integers or floats
      # and combine the arrays together
      #
      # @param [Hash] new_hash - the new hash to be merged together
      # @param [Hash] merge_hash - the hash to be merged into the new hash
      #
      # @return [Hash] - The merged query aggs into a unified hash
      def merge_hash!(new_hash, merge_hash)
        new_hash ||= {} # to avoid nil error
        merge_hash.each do |key, value|
          new_hash[key] = merge_values(new_hash[key], value)
        end
        new_hash
      end

      def merge_values(current_value, value)
        case value
        when Array   then (current_value || []) + value
        when Integer then current_value.to_i + value
        when Float   then current_value.to_f + value
        when Hash    then merge_hash!(current_value, value)
        else
          value
        end
      end

      def records
        @records ||= queries.flat_map(&:to_a)
      end

      def sum_and_sort_aggs_buckets_by_doc_count!(aggs) # rubocop:disable Metrics/AbcSize
        aggs.each do |agg_name, agg_data|
          next unless agg_data['buckets'].is_a?(Array)

          aggs[agg_name]['buckets'] = sum_buckets(agg_data['buckets'])
          next if aggs_options[agg_name.to_sym]&.keys&.intersect?(UNSORTABLE_AGGS)

          aggs[agg_name]['buckets'].sort_by! { -_1['doc_count'] }
        end
      end

      # merge doc_count for each bucket based on key
      def sum_buckets(buckets)
        buckets.each_with_object({}) do |bucket, hash|
          key, count = bucket.slice('key', 'doc_count').values
          hash[key] ||= bucket.except('doc_count')
          hash[key]['doc_count'] = merge_values(hash[key]['doc_count'], count)
        end.values
      end
    end
  end
end
