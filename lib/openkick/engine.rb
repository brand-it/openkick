# frozen_string_literal: true

require 'active_record/railtie'

module Openkick
  class Engine < ::Rails::Engine
    isolate_namespace Openkick

    initializer 'openkick.warn_classic_autoloader' do
      unless Rails.autoloaders.zeitwerk_enabled?
        raise <<~MSG.squish
          Autoloading in classic mode is not supported.
          Please use Zeitwerk to autoload your application.
        MSG
      end
    end

    # initializer "openkick.configs" do
    # end

    # config.to_prepare do
    # end

    # config.after_initialize do
    # end

    config.action_dispatch.rescue_responses.merge!(
      'Openkick::NotFoundError' => :not_found
    )
  end
end
