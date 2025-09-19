# frozen_string_literal: true

source 'https://rubygems.org'

ruby "3.0.7
"
# Framework
gem 'bundler' # TODO: remember why this is necessary
# gem 'rack-cors', :require => 'rack/cors'
gem 'puma'
#gem 'puma-daemon', require: false
# gem "unicorn"                          # Application server
gem 'rails', '6.0.6' # Rails framework
# gem "activesupport", "4.0.4"            # DEV-383: Newer versions conflict with state_machine
gem 'bcrypt' # Strong password hashing
gem 'customerio'
gem 'log4r'                            # Customisable log output
gem 'lograge'                          # More parseable rails request logging
gem 'rack-cors'                        # Easy CORS headers
gem 'responders'
gem 'declarative-option'
gem 'representable'
gem 'roar-rails'              # Representers, JSON input/output
gem 'redis-rails'
source "https://#{ENV['BUNDLE_GEMS__CONTRIBSYS__COM']}@gems.contribsys.com/" do
  gem 'sidekiq-pro' , '5.5.8'
end                                    # Background task processing
gem 'deep_cloneable'                   # Nested cloning of objects
gem 'dotenv', '2.8.1'                           # Easier environment variables
# Commenting need to remove
# gem 'newrelic_rpm'                     # NewRelic app server monitoring and tracing
gem 'pusher'                # Websocket service
gem 'sidekiq-failures'                 # Keep track of Sidekiq failed jobs
gem 'sidekiq-middleware'               # Sidekiq uniq jobs
gem 'sinatra'                          # Sidekiq dependency
gem 'statsd-ruby'                      # Communicate with statsd server
# gem 'unicorn-worker-killer'            # Kills workers at threshold of 250mb

gem 'netaddr', '~> 1.5', '>= 1.5.1'
# gem 'netaddr'                          # For CIDR & IP helpers
gem 'whenever', require: false # Cron jobs in Ruby
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
# for implement Google's MFA authenticator
gem 'google-authenticator-rails'

# Authentication/Authorisation
gem 'devise' # User authentication stuff
gem 'jwt'
# gem 'devise', git: 'https://github.com/gogovan/devise.git', branch: 'rails-5.1'
gem 'authority'                        # Authorisation for classes/objects
gem 'erubis'
gem 'rolify'                           # Role based access control

# Application
gem 'state_machines-activerecord'
# gem 'fog-aws'#, git: 'https://github.com/chanakyad-cuelogic/fog-aws.git' # till fog-aws merges snapshot.rb
gem 'fog-aws' # , '~> 3.5'
# gem "fog"#, '1.38.0'                    # Communicate with cloud providers
# gem 'awscosts', git: 'https://github.com/atish-cuelogic/awscosts.git', branch: 'hotfix/ebs_cost' # AWSCosts allows programmatic access to AWS pricing.
gem 'awscosts' #TODO need to confirm
# gem 'azure', git: 'https://github.com/hardikj-cuelogic/azure-sdk-for-ruby.git' # Because fog doesn't support Azure, we are useing the Azure SDK gem
gem 'azure'
gem 'config' # provides support for multi-environment yaml settings
gem 'rubyzip'                          # for reading and writing zip files
gem 'unf'                              # Dependency of fog for string encoding
gem 'wicked_pdf'                       # serve PDF file to a user from HTML
gem 'wkhtmltopdf-binary'
gem 'wkhtmltopdf-installer'
gem 'zip-zip'                          # for supporting rubyzip

gem 'bson_ext' # binary json dependency mongo db
gem 'mongoid', '~> 7.3.0' #TODO need to update it later 
gem 'moped'
gem 'pg'                               # PostgreSQL database
gem 'rake'                             # Tasks, etc

# gem "bson", "2.3.0"
gem 'aws-sdk', '3.0.1'
gem 'dynamoid', '3.7.1' # TODO: Should remove but need to check its dependency on config/initializers/dynamoid_config.rb file

# helpers
gem 'ice_cube', '~> 0.16.2' 
gem 'similar_text'
gem 'json', '~> 2.6.3'
gem 'next_rails'
gem 'ancestry', '3.0.1'
gem 'axlsx'
gem 'fat_zebra'
gem 'sunspot_rails'
gem 'sunspot_solr'

# azure arm gems
gem 'azure_mgmt_commerce'
gem 'azure_mgmt_compute'
gem 'azure_mgmt_cost_management'
gem 'azure_mgmt_mariadb'
gem 'azure_mgmt_monitor'
gem 'azure_mgmt_advisor'
gem 'azure_mgmt_mysql'
gem 'azure_mgmt_network'
gem 'azure_mgmt_postgresql'
gem 'azure_mgmt_resources'
gem 'azure_mgmt_sql'
gem 'azure_mgmt_storage'
gem 'azure_mgmt_subscriptions'
gem "ms_rest_azure", '0.12.0'
gem 'slack-ruby-client'

gem 'httparty'
gem 'parallel_tests', group: [:development, :test]
# gem 'foreigner'

gem 'faker'
gem 'request_store'

gem 'yajl-ruby', require: 'yajl'

group :test, :development do
  gem 'database_cleaner', git: 'https://github.com/DatabaseCleaner/database_cleaner.git' # used to ensure a clean state for testing
  gem 'rspec-collection_matchers'
  gem 'rspec-expectations'
  gem 'rspec-its' # RSpec::Its provides the its method as a short-hand to specify the expected value of an attribute.
  gem 'shoulda-matchers'
  gem 'factory_bot_rails', '4.8.2'
  #   gem "simplecov"
  #   gem "codeclimate-test-reporter"
  gem 'mock_redis', '0.16.1'
  gem 'rspec-roar_matchers', git: 'https://github.com/chanakyad-cuelogic/rspec-roar_matchers.git' # representers specs for rspec
  gem 'rspec-sidekiq' # sidekiq testing
end

group :test, :development, :marketplace_development do
  # gem 'rspec', '3.6.0'
  # gem 'rspec-rails', '3.6.1'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'simplecov', require: false
  gem 'webmock', require: false
  # gem "capybara" ,
  # gem "fuubar" ,
  # gem "rubocop" ,
  # gem "mutant-rspec" ,
end

group :staging, :production do
  
  # gem 'rspec', '3.6.0'
  gem 'rspec-rails' 
end

group :deployment do
  gem 'awesome_print'
  gem 'pry-byebug'
  gem 'sshkit'
end

gem 'honeybadger'

group :development, :marketplace_development do
  #  gem "rack-mini-profiler"
  #  gem "flamegraph"
  gem 'bullet'

  #   # Debugging
  gem 'pry'
  #   gem "hirb"
  # gem 'puma'
  # gem 'byebug'

  #   # Documentation
  # gem "rails-erd"
  # gem 'railroady'

  # Better Errors
  # gem "better_errors"
  # gem "binding_of_caller"
end
gem 'activerecord-import'
gem 'memoist', '0.15.0'
gem 'ruby-saml'
# gem "rails-observers"
# gem "foreigner"
# gem "immigrant"
# gem "oj"
# gem "faraday"
# gem "bond"
# gem "daemons"
# gem "daemons-rails"
# gem "random-walk"
# gem "slim"
# gem "cql-rb" github: "iconara/cql-rb"
# gem "ruby-graphviz"
gem 'will_paginate'
gem 'will_paginate_mongoid'
# gem 'foreigner'

# Use Uglifier as compressor for JavaScript assets
gem 'listen'
# gem 'active_model_serializers', '~> 0.10.0'
gem 'active_record_upsert'
gem 'bugsnag'
gem 'domainatrix'
gem 'rest-client', '~> 2.0.2'
gem 'googleauth' #need to confirm with tushar about the impact
gem 'google-api-client'
gem 'scout_apm'

gem 'carrierwave', '~> 1.3'
gem 'google-cloud-bigquery'

group :development, :test do
  gem 'rswag-specs', '2.5.1'
end
gem 'rswag'
gem 'servicenow-api'
gem 'active_record_union', '~> 1.3'
gem "resolv-replace" #to fix timeout

# Feature flag support
flipper_version = '~> 1.1.2'
gem 'flipper', flipper_version
#flipper storage adapter we have other options as well like https://www.flippercloud.io/docs/adapters
gem 'flipper-active_record', flipper_version
gem 'flipper-ui',flipper_version

gem "openid_connect", "~> 1.1.3"
