# frozen_string_literal: true

module Openkick
  module Model
    module Base
      # Don't load openkick onto any models unless this method is called
      def openkick(**options)
        require_relative 'class_methods'
        require_relative 'instance_methods'
        include InstanceMethods
        extend ClassMethods
        openkick_setup(**options)
      end
    end
  end
end
