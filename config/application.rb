require File.expand_path('../boot', __FILE__)

require 'rails/all'

require_relative 'constants'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

# Fixes fog cname s3 certificate issue
# Excon::Errors::SocketError (hostname does not match the server certificate (OpenSSL::SSL::SSLError)):
#   app/controllers/locker/avatars_controller.rb:65:in `create'
#   config/initializers/flash_json_content_type_middleware.rb:13:in `call'
#   config/initializers/flash_session_cookie_middleware.rb:16:in `call'
Fog.credentials = { path_style: true }


module Worlize
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{config.root}/extras )

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    config.generators do |g|
      g.stylesheets false
      g.javascripts false
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure default url generation options for mailers
    config.action_mailer.default_url_options = { :host => 'www.worlize.com', :protocol => 'https' }

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
    
    # Enable the asset pipeline
    config.assets.enabled = true
    
    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Manually add web fonts path
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    
    # Add vendor assets path
    config.assets.paths << Rails.root.join('vendor')
    
    # Precompile additional assets
    config.assets.precompile += %w( .svg .eot .woff .ttf )
    
    # Precompile flash assets
    config.assets.precompile += %w( .swf .swc .swz )
    
    # Don't initialize full rails app during precompilation
    config.assets.initialize_on_precompile = false

    # Add extra manifests for precompilation
    config.assets.precompile += [
      /admin.(css|js)$/,
      /bootstrap.(css|js)$/,
      /enter.(css|js)$/,
      /facebook_canvas.(css|js)$/,
      /marketplace.(css|js)$/,
      /plain.(css|js)$/
    ]
  end
end
