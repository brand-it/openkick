# frozen_string_literal: true

module Openkick
  class Query
    class Fields
      extend Forwardable
      include Enumerable

      def_delegators :fields, :each, :any?, :all?, :empty?, :size, :length, :==, :!=

      def initialize(term, options:, openkick_options:)
        @term = term
        @field_options = Array.wrap(
          options[:fields] ||
          openkick_options[:default_fields] ||
          openkick_options[:searchable]
        )
        @all = openkick_options.key?(:_all) ? openkick_options[:_all] : false
        @match = (options[:match] || openkick_options[:match] || :word).to_sym
        @boost_fields = {}
      end

      def self.call(...)
        new(...).call
      end

      def fields
        @fields ||= build_fields
      end

      def each_with_factor
        fields.each { |f| yield(f, @boost_fields[f] || 1.0) }
      end

      private

      attr_reader :openkick_options, :match, :field_options, :term, :all

      def build_fields
        if field_options.any?
          field_options.map { |field| parse_field(field) }
        elsif all_match_word?
          ['_all']
        elsif all_match_phrase?
          ['_all.phrase']
        elsif missing_searchable?
          raise ArgumentError, 'Must specify fields to search'
        else
          [match == :word ? '*.analyzed' : "*.#{match}"]
        end
      end

      def missing_searchable?
        term != '*' && match == :exact
      end

      def all_match_phrase?
        all && match == :phrase
      end

      def all_match_word?
        all && match == :word
      end

      def parse_field(field)
        k, v = field.is_a?(Hash) ? field.to_a.first : [field, match]
        k2, boost = k.to_s.split('^', 2)
        field = "#{k2}.#{v == :word ? 'analyzed' : v}"
        @boost_fields[field] = boost.to_f if boost
        field
      end
    end
  end
end
