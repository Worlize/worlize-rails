Worlize::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true
  
  # Compress JavaScript and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true
  
  # Use a manifest path that's checked into git
  config.assets.manifest = Rails.root.join('config')
  
  # Add flash client path
  config.assets.paths << Rails.root.join('lib', 'flash_client')
  
  # Notify deprecation notices
  config.active_support.deprecation = :notify
  
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :sendmail

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "https://www.worlize.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!
end
