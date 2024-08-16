ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.require(:default)
require 'minitest/autorun'
require 'active_support/notifications'

# for reloadable synonyms
if ENV['CI']
  ENV['ES_PATH'] ||= File.join(ENV.fetch('HOME', nil), Openkick.client.opensearch? ? 'opensearch' : 'elasticsearch',
                               Openkick.client.version)
end

$logger = ActiveSupport::Logger.new(ENV['VERBOSE'] ? STDOUT : nil)

if ENV['LOG_TRANSPORT']
  transport_logger = ActiveSupport::Logger.new(STDOUT)
  if Openkick.client.transport.respond_to?(:transport)
    Openkick.client.transport.transport.logger = transport_logger
  else
    Openkick.client.transport.logger = transport_logger
  end
end
Openkick.search_timeout = 5
Openkick.index_suffix = ENV.fetch('TEST_ENV_NUMBER', nil) # for parallel tests

puts "Running against #{Openkick.client.name}"

I18n.config.enforce_available_locales = true

ActiveJob::Base.logger = $logger
ActiveJob::Base.queue_adapter = :test

ActiveSupport::LogSubscriber.logger = ActiveSupport::Logger.new(STDOUT) if ENV['VERBOSE']

if defined?(Mongoid)
  require_relative 'support/mongoid'
else
  require_relative 'support/activerecord'
end

require_relative 'support/redis'

# models
Dir["#{__dir__}/models/*"].each do |file|
  require file
end

require_relative 'support/helpers'
