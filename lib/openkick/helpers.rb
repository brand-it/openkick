# frozen_string_literal: true

module Openkick
  module Helpers
    private

    def indexer
      Thread.current[:openkick_indexer] ||= Indexer.new
    end

    def callbacks_value
      Thread.current[:openkick_callbacks_enabled]
    end

    def callbacks_value=(value)
      Thread.current[:openkick_callbacks_enabled] = value
    end

    # methods are forwarded to base class
    # this check to see if scope exists on that class
    # it's a bit tricky, but this seems to work
    def relation?(klass)
      return false if klass.nil?

      if klass.respond_to?(:current_scope)
        !klass.current_scope.nil?
      elsif defined?(::Mongoid)
        klass.is_a?(::Mongoid::Criteria) || !::Mongoid::Threaded.current_scope(klass).nil?
      else
        raise Error, "#{klass} does respond to current_scope and Mongoid is not defined"
      end
    end

    def scope(model)
      # safety check to make sure used properly in code
      raise Error, 'Cannot scope relation' if relation?(model)

      if model.openkick_options[:unscope]
        model.unscoped
      else
        model
      end
    end

    def load_records(relation, ids)
      relation =
        if relation.respond_to?(:primary_key)
          primary_key = relation.primary_key
          raise Error, 'Need primary key to load records' unless primary_key

          relation.where(primary_key => ids)
        elsif relation.respond_to?(:queryable)
          relation.queryable.for_ids(ids)
        end

      raise Error, 'Not sure how to load records' unless relation

      relation
    end

    def not_found_error?(exception)
      (defined?(Elastic::Transport) && exception.is_a?(Elastic::Transport::Transport::Errors::NotFound)) ||
        (defined?(Elasticsearch::Transport) && exception.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound)) ||
        (defined?(OpenSearch) && exception.is_a?(OpenSearch::Transport::Transport::Errors::NotFound))
    end

    def transport_error?(exception)
      (defined?(Elastic::Transport) && exception.is_a?(Elastic::Transport::Transport::Error)) ||
        (defined?(Elasticsearch::Transport) && exception.is_a?(Elasticsearch::Transport::Transport::Error)) ||
        (defined?(OpenSearch) && exception.is_a?(OpenSearch::Transport::Transport::Error))
    end

    def not_allowed_error?(exception)
      (
        defined?(Elastic::Transport) &&
          exception.is_a?(Elastic::Transport::Transport::Errors::MethodNotAllowed)
      ) ||
        (
          defined?(Elasticsearch::Transport) &&
        exception.is_a?(Elasticsearch::Transport::Transport::Errors::MethodNotAllowed)
        ) ||
        (
          defined?(OpenSearch) &&
          exception.is_a?(OpenSearch::Transport::Transport::Errors::MethodNotAllowed)
        )
    end

    def warn(message)
      ActiveSupport::Deprecation.new.warn("[openkick] WARNING: #{message}")
    end
  end
end
