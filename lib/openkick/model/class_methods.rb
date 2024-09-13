# frozen_string_literal: true

module Openkick
  module Model
    module ClassMethods
      KNOWN_KEYWORDS = %i[
        _all _type batch_size callbacks
        case_sensitive conversions deep_paging default_fields
        filterable geo_shape highlight ignore_above index_name index_prefix inheritance language
        locations mappings match max_result_window merge_mappings routing searchable search_synonyms settings similarity
        special_characters stem stemmer stem_conversions stem_exclusion stemmer_override suggest synonyms text_end
        text_middle text_start unscope word word_end word_middle word_start
      ].freeze

      CALLBACK_TYPES = [:inline, true, false, :async, :queue].freeze
      CALLBACK_DEFAULT = :inline

      def self.extended(base)
        # always add callbacks, even when callbacks is false
        # so Model.callbacks block can be used
        if base.respond_to?(:after_commit)
          base.after_commit :reindex, if: -> { Openkick.callbacks?(default: base.openkick_options[:callbacks]) }
        elsif base.respond_to?(:after_save)
          base.after_save :reindex, if: -> { Openkick.callbacks?(default: base.openkick_options[:callbacks]) }
          base.after_destroy :reindex, if: -> { Openkick.callbacks?(default: base.openkick_options[:callbacks]) }
        end
        base.cattr_reader :openkick_options, :openkick_klass, instance_reader: false
        base.class_variable_set :@@openkick_options, Openkick.model_options.dup
        base.class_variable_set :@@openkick_klass, base
        base.class_variable_set :@@openkick_index_cache, Openkick::IndexCache.new
      end

      def openkick_search(term = '*', **options, &)
        Openkick.search(term, model: self, **options, &)
      end
      alias_method Openkick.search_method_name, :openkick_search if Openkick.search_method_name

      def openkick_index(name: nil)
        index_name = name || openkick_klass.openkick_index_name
        index_name = index_name.call if index_name.respond_to?(:call)
        openkick_index_cache.fetch(index_name) { Openkick::Index.new(index_name, openkick_options) }
      end
      alias search_index openkick_index unless method_defined?(:search_index)

      def openkick_reindex(method_name = nil, **options)
        openkick_index.reindex(self, method_name:, **options)
      end
      alias reindex openkick_reindex unless method_defined?(:reindex)

      # Defines a callback to reindex an associated model after a commit,
      # with support for specifying a custom method name for reindexing.
      #
      # Usage: `after_commit_reindex :association, **options`
      #
      # This method defines an `after_commit` callback that triggers the
      # reindexing of the specified association when the parent model is saved.
      # It is designed to work with the Searchkick gem to reindex the associated
      # model after a database commit has occurred, with an optional ability to
      # specify a custom method for reindexing.
      #
      # Parameters:
      # - `association` (Symbol): The name of the association to reindex.
      # - `options` (Hash, optional): Additional options for the callback.
      #   - `:if` (Symbol, optional): Condition for running the callback.
      #   - `:unless` (Symbol, optional): Condition for skipping the callback.
      #   - `:on` (Symbol, optional): Specify which action to trigger the callback on
      #     (`:create`, `:update`, or `:destroy`).
      #   - `:except` (Array, optional): Skip the callback on specific actions.
      #   - `:method_name` (Symbol, optional): Custom method name to call when
      #     reindexing. If provided, this method will be passed to the `reindex`
      #     function of the association.
      #
      # Example usage:
      #
      #   after_commit_reindex :items, if: :saved_change_to_published?
      #   after_commit_reindex :items, unless: :saved_change_to_published?
      #   after_commit_reindex :items, except: [:create, :update]
      #   after_commit_reindex :items, on: :create
      #   after_commit_reindex :items, partial: :custom_reindex_method
      #
      # Customization:
      # You can override the reindexing behavior for the association by
      # defining a custom method `reindex_<association>`. For example:
      #
      #   def reindex_items
      #     items.reindex(:custom_reindex_method)
      #   end
      #
      # This method will automatically define a `reindex_<association>` method
      # if one does not already exist, which is responsible for reindexing the
      # associated records using Searchkick. If the `:method_name` option is
      # passed, that method name will be provided to the `reindex` method of
      def after_commit_reindex(association, **options)
        partial = options.delete(:partial)
        unless method_defined?(:"reindex_#{association}")
          define_method(:"reindex_#{association}") do
            return unless Openkick.callbacks?

            send(association)&.reindex(partial)
          end
        end
        if respond_to?(:after_commit)
          # ActiveRecord callbacks
          after_commit :"reindex_#{association}", options
        elsif respond_to?(:after_save)
          # Mongoid-specific callbacks
          after_save :"reindex_#{association}", options
        else
          raise 'Could not implement after_commit_reindex model does not support after_safe or after_commit'
        end
      end

      def openkick_index_options
        openkick_index.index_options
      end

      def openkick_index_name
        @openkick_index_name ||= openkick_options[:index_name] ||
                                 [
                                   openkick_index_prefix,
                                   model_name.plural,
                                   Openkick.env,
                                   Openkick.index_suffix
                                 ].compact.join('_')
      end

      private

      def openkick_setup(**options)
        openkick_options.merge!(options)

        validate_openkick_options!
        Openkick.models << self

        openkick_options[:_type] ||= -> { openkick_index.klass_document_type(self, true) }
        openkick_options[:class_name] = model_name.name
        openkick_options[:callbacks] = CALLBACK_DEFAULT unless openkick_options.key?(:callbacks)

        return if CALLBACK_TYPES.include?(openkick_options[:callbacks])

        raise ArgumentError, 'Invalid value for callbacks'
      end

      def openkick_index_cache
        class_variable_get(:@@openkick_index_cache)
      end

      def openkick_index_prefix
        return Openkick.index_prefix unless openkick_options.key?(:index_prefix)

        index_prefix = openkick_options[:index_prefix]
        return index_prefix.call if index_prefix.respond_to?(:call)

        index_prefix
      end

      def validate_openkick_options!
        if (unknown_keywords = openkick_options.keys - KNOWN_KEYWORDS).any?
          raise ArgumentError, "unknown keywords: #{unknown_keywords.join(', ')}"
        end
        return if Openkick.models.exclude?(self)

        raise "Openkick already defined for #{name}. Only call openkick once per model"
      end
    end
  end
end
