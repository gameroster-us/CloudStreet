# frozen_string_literal: true

require 'flipper/adapters/active_record'
require_relative "../../lib/feature_flags/adapters/active_record_based"

Rails.application.reloader.to_prepare do
  Flipper.configure do |config|
    config.adapter { FeatureFlags::Adapters::ActiveRecordBased.new }
  end
end