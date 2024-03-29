require 'rack/utils'
 
module Worlize
  module Middleware
    class FlashSessionCookieMiddleware
      def initialize(app)
        @app = app
      end
 
      def call(env)
        req = Rack::Request.new(env)
        if !req.params['cookie'].nil?
          env['HTTP_COOKIE'] = req.params['cookie']
        end
    
        @app.call(env)
      end
    end
  end
end

Rails.configuration.middleware.insert_after(ActionDispatch::Cookies, Worlize::Middleware::FlashSessionCookieMiddleware)