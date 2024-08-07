# based on https://gist.github.com/mnutt/566725
module Openkick
  module ControllerRuntime
    extend ActiveSupport::Concern

    protected

    attr_internal :openkick_runtime

    def process_action(action, *args)
      # We also need to reset the runtime before each action
      # because of queries in middleware or in cases we are streaming
      # and it won't be cleaned up by the method below.
      Openkick::LogSubscriber.reset_runtime
      super
    end

    def cleanup_view_runtime
      openkick_rt_before_render = Openkick::LogSubscriber.reset_runtime
      runtime = super
      openkick_rt_after_render = Openkick::LogSubscriber.reset_runtime
      self.openkick_runtime = openkick_rt_before_render + openkick_rt_after_render
      runtime - openkick_rt_after_render
    end

    def append_info_to_payload(payload)
      super
      payload[:openkick_runtime] = (openkick_runtime || 0) + Openkick::LogSubscriber.reset_runtime
    end

    module ClassMethods
      def log_process_action(payload)
        messages = super
        runtime = payload[:openkick_runtime]
        messages << (format('Openkick: %.1fms', runtime.to_f)) if runtime.to_f > 0
        messages
      end
    end
  end
end
