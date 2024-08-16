# frozen_string_literal: true

module Openkick
  class Settings
    VALID_CLIENT_TYPES = %i[opensearch elasticsearch].freeze
    DELGATABLE_METHODS = %i[
      aws_credentials
      client
      client_options
      env
      index_prefix
      index_suffix
      model_options
      models
      queue_name
      redis
      search_method_name
      search_timeout
      timeout
    ].flat_map { |m| [m, :"#{m}="] }.freeze

    attr_accessor :index_prefix,
                  :index_suffix,
                  :redis

    attr_writer :client,
                :env,
                :search_timeout,
                :search_method_name,
                :timeout,
                :models,
                :client_options,
                :queue_name,
                :model_options
    attr_reader :aws_credentials

    def search_timeout
      (defined?(@search_timeout) && @search_timeout) || timeout
    end

    def aws_credentials=(creds)
      require 'faraday_middleware/aws_sigv4'

      @aws_credentials = creds
      @client = nil # reset client
    end

    def search_method_name
      @search_method_name ||= :search
    end

    def timeout
      @timeout ||= 10
    end

    def models
      @models ||= []
    end

    def client_options
      @client_options ||= {}
    end

    def queue_name
      @queue_name ||= :openkick
    end

    def model_options
      @model_options ||= {}
    end

    def client_type=(type)
      unless VALID_CLIENT_TYPES.include?(type.to_sym)
        raise Error, "#{type} is not valid, use #{VALID_CLIENT_TYPES.join(', ')}"
      end

      @client_type = type.to_sym
    end

    def client_type
      return @client_type if @client_type

      if defined?(OpenSearch::Client) && defined?(Elasticsearch::Client)
        raise Error,
              'Multiple clients found - set Openkick.client_type = :elasticsearch or :opensearch'
      end
      return @client_type = :opensearch if defined?(OpenSearch::Client)
      return @client_type = :elasticsearch if defined?(Elasticsearch::Client)

      raise Error, 'No client found - install the `elasticsearch` or `opensearch-ruby` gem'
    end

    def signer_middleware_aws_params
      { service: 'es', region: 'us-east-1' }.merge(aws_credentials)
    end
  end
end
