require 'faraday'

module Openkick
  class Middleware < Faraday::Middleware
    def call(env)
      path = env[:url].path.to_s
      if path.end_with?('/_search')
        env[:request][:timeout] = Openkick.search_timeout
      elsif path.end_with?('/_msearch')
        # assume no concurrent searches for timeout for now
        searches = env[:request_body].count("\n") / 2
        # do not allow timeout to exceed Openkick.timeout
        timeout = [Openkick.search_timeout * searches, Openkick.timeout].min
        env[:request][:timeout] = timeout
      end
      @app.call(env)
    end
  end
end
