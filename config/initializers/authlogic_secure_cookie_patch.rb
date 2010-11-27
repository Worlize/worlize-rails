# /config/initializers/authlogic_secure_cookie_patch.rb
#
# This patch makes authlogic's persistence cookie
# secure to prevent HTTP session hijacking
module Authlogic
  module Session
    module Cookies
      module InstanceMethods
 
      private
 
        def save_cookie
          controller.cookies[cookie_key] = {
            :value => "#{record.persistence_token}::#{record.send(record.class.primary_key)}",
            :expires => remember_me_until,
            :domain => controller.cookie_domain,
            :secure => Rails.env.production?, # Only send cookie over SSL when in production mode
            :httponly => true
          }
        end
      end
    end
  end
end