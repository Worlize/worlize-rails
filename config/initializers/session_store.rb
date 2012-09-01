# Be sure to restart your server when you modify this file.

session_options = {}
if Rails.env == 'production'
  session_options[:key] = '_wzses'
else
  session_options[:key] = '_dev_wzses'
end
session_options[:domain] = :all
session_options[:secure] = true

Rails.application.config.session_store :cookie_store, session_options

# Rails.application.config.session_store :active_record_store, :domain => :all

# Use redis as our session store.
# Rails.application.config.session_store :redis_session_store

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#Rails.application.config.session_store :active_record_store
#Rails.application.config.session_store :redis_session_store
