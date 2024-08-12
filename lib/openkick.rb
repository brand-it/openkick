# dependencies
require 'active_support'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/module/attr_internal'
require 'active_support/core_ext/module/delegation'
require 'active_support/environment_inquirer'
require 'active_support/notifications'
require 'hashie'

# stdlib
require 'forwardable'

# Classes
require_relative 'openkick/query/deep_merge'
require_relative 'openkick/query/field_value_factor'
require_relative 'openkick/query/fields'
require_relative 'openkick/query/opensearch/neural'
require_relative 'openkick/query/opensearch/reranking'

# modules
require_relative 'openkick/client'
require_relative 'openkick/controller_runtime'
require_relative 'openkick/error'
require_relative 'openkick/hash_wrapper'
require_relative 'openkick/helpers'
require_relative 'openkick/index_cache'
require_relative 'openkick/index_options'
require_relative 'openkick/index'
require_relative 'openkick/indexer'
require_relative 'openkick/log_subscriber'
require_relative 'openkick/model/base'
require_relative 'openkick/multi_search'
require_relative 'openkick/query'
require_relative 'openkick/raw'
require_relative 'openkick/search'
require_relative 'openkick/record_data'
require_relative 'openkick/record_indexer'
require_relative 'openkick/reindex_queue'
require_relative 'openkick/relation_indexer'
require_relative 'openkick/relation'
require_relative 'openkick/results'
require_relative 'openkick/settings'
require_relative 'openkick/version'
require_relative 'openkick/where'

# integrations
require_relative 'openkick/railtie' if defined?(Rails)

module Openkick
  # requires faraday
  autoload :Middleware, 'openkick/middleware'

  # background jobs
  autoload :BulkReindexJob,  'openkick/bulk_reindex_job'
  autoload :ProcessBatchJob, 'openkick/process_batch_job'
  autoload :ProcessQueueJob, 'openkick/process_queue_job'
  autoload :ReindexV2Job,    'openkick/reindex_v2_job'

  class << self
    extend Forwardable
    include Helpers

    def settings
      @settings ||= Openkick::Settings.new
    end

    def_delegators :settings, *Openkick::Settings::DELGATABLE_METHODS

    def client
      @client ||= Openkick::Client.new(settings)
    end

    def env
      @env ||= ActiveSupport::EnvironmentInquirer.new(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development')
    end

    def search(term = '*', model: nil, **options, &block)
      Openkick::Search.new(term, model:, **options).call(&block)
    end

    def multi_search(queries)
      return if queries.empty?

      queries = queries.map { |q| q.send(:query) }
      event = {
        name: 'Multi Search',
        body: queries.flat_map { |q| [q.params.except(:body).to_json, q.body.to_json] }.map { |v| "#{v}\n" }.join
      }
      ActiveSupport::Notifications.instrument('multi_search.openkick', event) do
        MultiSearch.new(queries).perform
      end
    end

    # raw

    # experimental
    def raw(value)
      Raw.new(value)
    end

    # callbacks
    def enable_callbacks
      self.callbacks_value = nil
    end

    def disable_callbacks
      self.callbacks_value = false
    end

    def callbacks?(default: true)
      if callbacks_value.nil?
        default
      else
        callbacks_value != false
      end
    end

    def reindex_status(index_name)
      raise Error, 'Redis not configured' unless redis

      batches_left = Index.new(index_name).batches_left
      {
        completed: batches_left == 0,
        batches_left:
      }
    end

    def with_redis(&)
      return unless redis

      if redis.respond_to?(:with)
        redis.with(&)
      else
        yield redis
      end
    end

    def load_model(class_name, allow_child: false)
      model = class_name.safe_constantize
      raise Error, "Could not find class: #{class_name}" unless model

      if allow_child
        raise Error, "#{class_name} is not a openkick model" unless model.respond_to?(:openkick_klass)
      else
        raise Error, "#{class_name} is not a openkick model" unless Openkick.models.include?(model)
      end
      model
    end

    def callbacks(value = nil, message: nil)
      if block_given?
        previous_value = callbacks_value
        begin
          self.callbacks_value = value
          result = yield
          if callbacks_value == :bulk && indexer.queued_items.any?
            event = {}
            if message
              message.call(event)
            else
              event[:name] = 'Bulk'
              event[:count] = indexer.queued_items.size
            end
            ActiveSupport::Notifications.instrument('request.openkick', event) do
              indexer.perform
            end
          end
          result
        ensure
          self.callbacks_value = previous_value
        end
      else
        self.callbacks_value = value
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend Openkick::Model::Base
end

ActiveSupport.on_load(:mongoid) do
  Mongoid::Document::ClassMethods.extend Openkick::Model::Base
end

ActiveSupport.on_load(:action_controller) do
  include Openkick::ControllerRuntime
end

Openkick::LogSubscriber.attach_to :openkick
