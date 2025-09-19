
if ENV["HONEYBADGER_API_KEY"]
	require "honeybadger"

	Honeybadger.configure do |config|
	  config.api_key = Rails.configuration.honeybadger[:api_key]
	  config.env = ENV["RAILS_ENV"]
	  # config.params_filters << ""
	end
end
