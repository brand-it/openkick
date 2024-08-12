# frozen_string_literal: true

module Openkick
  class Query
    class DeepMerge
      # Merges to hash together as a single hash.
      # Also sum the values if they are integers or floats
      # and combine the arrays together
      #
      # @param [Hash] new_hash - the new hash to be merged together
      # @param [Hash] merge_hash - the hash to be merged into the new hash
      #
      # @return [Hash] - The merged query aggs into a unified hash
      def self.merge_hash!(new_hash, merge_hash)
        new_hash ||= {} # to avoid nil error
        merge_hash.each do |key, value|
          new_hash[key] = merge_values(new_hash[key], value)
        end
        new_hash
      end

      def self.merge_values(current_value, value)
        case value
        when Array   then (current_value || []) + value
        when Integer then current_value.to_i + value
        when Float   then current_value.to_f + value
        when Hash    then merge_hash!(current_value, value)
        else
          value
        end
      end
    end
  end
end
