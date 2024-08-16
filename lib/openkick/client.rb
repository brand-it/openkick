# frozen_string_literal: true

module Openkick
  class Client
    extend Forwardable

    def initialize(settings)
      @settings = settings
    end

    def client
      @client ||= client_type == :opensearch ? opensearch_client : elasticsearch_client
    end

    def info
      @info ||= client.info
    end

    def version
      @version ||= info['version']['number'] || ''
    end

    def name
      opensearch? ? "Opensearch #{version}" : "Elasticsearch #{version}"
    end

    def opensearch?
      return @opensearch if defined?(@opensearch)

      @opensearch = info['version']['distribution'] == 'opensearch'
    end

    # TODO: always check true version in Openkick 6
    def server_below?(expected_version, true_version: false)
      server_version = !true_version && opensearch? ? '7.10.2' : version
      Gem::Version.new(server_version.split('-')[0]) < Gem::Version.new(expected_version.split('-')[0])
    end

    def method_missing(method_name, ...)
      if client.respond_to?(method_name)
        client.send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name, include_private) || super
    end

    private

    attr_reader :settings

    def_delegators :settings, :client_type, :client_options, :aws_credentials, :signer_middleware_aws_params, :timeout

    def elasticsearch_client
      raise Error, 'The `elasticsearch` gem must be 7+' if Elasticsearch::VERSION.to_i < 7

      Elasticsearch::Client.new(options) do |f|
        f.use Openkick::Middleware
        f.request :aws_sigv4, signer_middleware_aws_params if aws_credentials
      end
    end

    def opensearch_client
      OpenSearch::Client.new(options) do |f|
        f.use Openkick::Middleware
        f.request :aws_sigv4, signer_middleware_aws_params if aws_credentials
      end
    end

    def options
      {
        url:,
        transport_options:,
        retry_on_failure: 2
      }.deep_merge(client_options)
    end

    def url
      client_type == :opensearch ? ENV.fetch('OPENSEARCH_URL', nil) : ENV.fetch('ELASTICSEARCH_URL', nil)
    end

    def transport_options
      {
        request: { timeout: },
        headers: {
          content_type: 'application/json'
        }
      }
    end
  end
end
