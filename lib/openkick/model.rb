module Openkick
  module Model
    def openkick(**options)
      options = Openkick.model_options.merge(options)

      unknown_keywords = options.keys - %i[_all _type batch_size callbacks case_sensitive conversions deep_paging default_fields
                                           filterable geo_shape highlight ignore_above index_name index_prefix inheritance language
                                           locations mappings match max_result_window merge_mappings routing searchable search_synonyms settings similarity
                                           special_characters stem stemmer stem_conversions stem_exclusion stemmer_override suggest synonyms text_end
                                           text_middle text_start unscope word word_end word_middle word_start]
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(', ')}" if unknown_keywords.any?

      raise 'Only call openkick once per model' if respond_to?(:openkick_index)

      Openkick.models << self

      options[:_type] ||= -> { openkick_index.klass_document_type(self, true) }
      options[:class_name] = model_name.name

      callbacks = options.key?(:callbacks) ? options[:callbacks] : :inline
      unless [:inline, true, false, :async, :queue].include?(callbacks)
        raise ArgumentError, 'Invalid value for callbacks'
      end

      base = self

      mod = Module.new
      include(mod)
      mod.module_eval do
        unless base.method_defined?(:reindex)
          def reindex(method_name = nil, mode: nil, refresh: false)
            self.class.openkick_index.reindex([self], method_name:, mode:, refresh:, single: true)
          end
        end

        unless base.method_defined?(:similar)
          def similar(**options)
            self.class.openkick_index.similar_record(self, **options)
          end
        end

        unless base.method_defined?(:search_data)
          def search_data
            data = respond_to?(:to_hash) ? to_hash : serializable_hash
            data.delete('id')
            data.delete('_id')
            data.delete('_type')
            data
          end
        end

        unless base.method_defined?(:should_index?)
          def should_index?
            true
          end
        end
      end

      class_eval do
        cattr_reader :openkick_options, :openkick_klass, instance_reader: false

        class_variable_set :@@openkick_options, options.dup
        class_variable_set :@@openkick_klass, self
        class_variable_set :@@openkick_index_cache, Openkick::IndexCache.new

        class << self
          def openkick_search(term = '*', **options, &block)
            raise Openkick::Error, 'search must be called on model, not relation' if Openkick.relation?(self)

            Openkick.search(term, model: self, **options, &block)
          end
          alias_method Openkick.search_method_name, :openkick_search if Openkick.search_method_name

          def openkick_index(name: nil)
            index_name = name || openkick_klass.openkick_index_name
            index_name = index_name.call if index_name.respond_to?(:call)
            index_cache = class_variable_get(:@@openkick_index_cache)
            index_cache.fetch(index_name) { Openkick::Index.new(index_name, openkick_options) }
          end
          alias_method :search_index, :openkick_index unless method_defined?(:search_index)

          def openkick_reindex(method_name = nil, **options)
            openkick_index.reindex(self, method_name:, **options)
          end
          alias_method :reindex, :openkick_reindex unless method_defined?(:reindex)

          def openkick_index_options
            openkick_index.index_options
          end

          def openkick_index_name
            @openkick_index_name ||= begin
              options = class_variable_get(:@@openkick_options)
              if options[:index_name]
                options[:index_name]
              elsif options[:index_prefix].respond_to?(:call)
                -> { [options[:index_prefix].call, model_name.plural, Openkick.env, Openkick.index_suffix].compact.join('_') }
              else
                [options.key?(:index_prefix) ? options[:index_prefix] : Openkick.index_prefix, model_name.plural, Openkick.env, Openkick.index_suffix].compact.join('_')
              end
            end
          end
        end

        # always add callbacks, even when callbacks is false
        # so Model.callbacks block can be used
        if respond_to?(:after_commit)
          after_commit :reindex, if: -> { Openkick.callbacks?(default: callbacks) }
        elsif respond_to?(:after_save)
          after_save :reindex, if: -> { Openkick.callbacks?(default: callbacks) }
          after_destroy :reindex, if: -> { Openkick.callbacks?(default: callbacks) }
        end
      end
    end
  end
end
