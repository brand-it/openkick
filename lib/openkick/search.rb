# frozen_string_literal: true

module Openkick
  class Search
    include Helpers

    def initialize(term = '*', model: nil, **options)
      raise Error, "term must be a String but was a #{term.class}" if term && !term.is_a?(String)
      raise Error, 'search must be called on model, not relation' if relation?(model)

      @term = term
      @model = model
      @options = options.dup
    end

    def call(&block)
      convert_index_to_model
      make_search_equivalent
      class_or_options_inconsistent?

      @options.merge!(block:) if block
      Relation.new(@model, @term, **@options)
    end

    private

    # convert index_name into models if possible
    # this should allow for easier upgrade
    def convert_index_to_model
      if @options[:index_name] && !@options[:models] && Array(@options[:index_name]).all? do |v|
           v.respond_to?(:openkick_index)
         end
        @options[:models] = @options.delete(:index_name)
      end
    end

    def class_or_options_inconsistent?
      if @model && ((@options[:models] && Array(@options[:models]) != [@model]) || Array(@options[:index_name]).any? do |v|
                      v.respond_to?(:openkick_index) && v != @model
                    end)
        raise ArgumentError, 'Use Openkick.search to search multiple models'
      end
    end

    # make Openkick.search(models: [Product]) and Product.search equivalent
    def make_search_equivalent
      return if @model

      models = Array(@options[:models])
      return unless models.size == 1

      @model = @options.delete(:models).first
    end
  end
end
