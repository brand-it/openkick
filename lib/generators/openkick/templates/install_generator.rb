# frozen_string_literal: true

module Openkick
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    # Mounts the engine in the host application's config/routes.rb
    def mount_engine
      route('mount Openkick::Engine => "/openkick"')
    end
  end
end
