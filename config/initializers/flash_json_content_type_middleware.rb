require 'rack/utils'
module Worlize
  module Middleware
    class FlashJSONContentTypeMiddleware
      def initialize(app)
        @app = app
      end
 
      def call(env)
        if env['HTTP_ACCEPT'] && env['HTTP_ACCEPT'].downcase.include?('application/json')
          env['HTTP_ACCEPT'] = 'application/json'
        end
        @app.call(env)
      end
    end
  end
end

Rails.configuration.middleware.insert_after(ActionDispatch::Cookies, Worlize::Middleware::FlashJSONContentTypeMiddleware)