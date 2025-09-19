require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Log4r
require "log4r"
require "log4r/yamlconfigurator"
require "log4r/outputter/datefileoutputter"
require "lograge"
require 'responders'
require "roar-rails"

require "authority"
require "customerio"
# require "devise"
require "pusher"
require "rolify"
require "devise"

require "deep_cloneable"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/cloudstreet"
require_relative "../lib/CS_logger"
require_relative "../lib/CS_logger_formatter"

module CloudStreet::API
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0 
    config.api_only = true

    ActiveSupport.to_time_preserves_timezone = false

    self.paths['config/mongoid'] = '/data/mount/mongoid.yml' if File.exist?("/data/mount/mongoid.yml")

    # turn off CSRF protection in a rails app
    config.action_controller.allow_forgery_protection = false

    Log4r::GDC.set("cloudstreet::api")

    config.default_host = ENV["APP_HOST"]

    # For hypermedia links in roar to work
    config.representer.default_url_options = { host: "127.0.0.1:3000" }
    config.representer.represented_formats = [:hal, :json]

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]
    config.autoload_paths += Dir["#{config.root}/lib/marketplace/**/"] if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
    config.autoload_paths += %W(/data/marketplace-api/current/lib) if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
    config.autoload_paths += %W(#{config.root}/lib/machine_images)

    config.eager_load_paths += %W[#{config.root}/lib] 

    config.active_record.yaml_column_permitted_classes = [
      Date,
      Time,
      Symbol
    ]
    # config.autoload_paths += %W(#{config.root}/lib/**/**)
    # config.autoload_paths += %W(#{config.root}/app/**/** #{config.root}/lib/**/**) # For contexts/roles
    # config.autoload_paths += %W(/vagrant/CloudStreet-api-server/**/**)

    # eager loading provider_wrapper classes
    # why eagerloading instead of autoloading?
    # http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload/
    # And how to include all files recursively =>
    # http://stackoverflow.com/questions/7750769/recursively-including-all-model-subdirectories
    # config.eager_load_paths << Rails.root.join('app/values')
    # config.eager_load_paths << Rails.root.join('lib/wrappers')
    config.eager_load_paths += %W(#{config.root}/lib/machine_images)
    config.eager_load_paths += %W(#{config.root}/lib/sync/)
    config.eager_load_paths += ["#{config.root}/lib/workers"]

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record"s schema dumper when creating the database.
    config.active_record.schema_format = :sql

    config.generators do |g|
      g.javascripts false
      g.stylesheets false
      g.helper      false
      g.template_engine false
      g.orm :active_record
      g.test_framework   :rspec
      g.integration_tool :rspec
      g.performance_tool :rspec
    end

    # For removing session cookies from requests.
    config.middleware.delete ActionDispatch::Cookies
    config.middleware.delete ActionDispatch::Session::CookieStore
    config.middleware.delete ActionDispatch::Flash

    # Lograge configuration, must be here because of load order
    config.lograge.enabled = true
    
    if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        :enable_starttls_auto => true,
        :address => ENV['SMTP_HOST'],
        :port => ENV['SMTP_PORT'],
        :authentication => :plain,
        :user_name => ENV['SMTP_USERNAME'],
        :password => ENV['SMTP_PASSWORD']
      }
    
      config.smtp_from_email =  ENV['SMTP_FROM_EMAIL']
    end   

    config.set_smtp = ENV['SMTP_SET'] || "false"
    config.customerio = {
      site_id: ENV['CUSTOMERIO_SITE_ID'],
      api_key: ENV['CUSTOMERIO_API_KEY'],
      api_client_key: ENV['CUSTOMERIO_API_CLIENT_KEY']
    }

    config.honeybadger = {
      api_key: ENV['HONEYBADGER_API_KEY']
    }

    config.enable_dependency_loading = true
    config.active_record.belongs_to_required_by_default = false

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
